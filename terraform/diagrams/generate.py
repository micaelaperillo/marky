#!/usr/bin/env python3
"""
Marky — AWS Architecture Diagram Generator

Generates a PNG diagram of the Marky infrastructure using the `diagrams` library.

Usage:
    pip install diagrams
    python generate.py

Requires graphviz system package:
    sudo apt install graphviz    # Debian/Ubuntu
    brew install graphviz        # macOS
"""

from diagrams import Cluster, Diagram, Edge

from diagrams.aws.compute import Lambda
from diagrams.aws.database import RDS, Dynamodb, RDSInstance
from diagrams.aws.integration import SQS, SNS, Eventbridge
from diagrams.aws.network import APIGateway, Endpoint
from diagrams.aws.security import Cognito, SecretsManager
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch
from diagrams.generic.network import Firewall

graph_attr = {
    "fontsize": "28",
    "bgcolor": "white",
    "pad": "0.8",
    "nodesep": "0.8",
    "ranksep": "1.2",
}

with Diagram(
    "Marky — Bluesky Sentiment Analysis",
    filename="marky-architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    outformat="png",
):
    user = APIGateway("API Gateway\nREST (Regional)")
    cognito = Cognito("Cognito\nUser Pool")

    s3_frontend = S3("S3 Frontend\n(SvelteKit)")
    s3_posts = S3("S3 Posts\n(versioned)")

    with Cluster("API Lambdas"):
        auth_lambda = Lambda("Auth")
        reports_lambda = Lambda("Reports")

    with Cluster("VPC — Private (no IGW/NAT)"):
        with Cluster("Subnets (2 AZs)"):
            campaigns_lambda = Lambda("Campaigns\n(VPC)")

        with Cluster("RDS"):
            rds_proxy = RDS("RDS Proxy\nTLS + SECRETS")
            rds_instance = RDSInstance("PostgreSQL 16\nt4g.micro\nPerf Insights")

        with Cluster("VPC Endpoints"):
            vpce_sqs = Endpoint("SQS")
            vpce_sm = Endpoint("Secrets Mgr")
            vpce_logs = Endpoint("CW Logs")

    rds_secret = SecretsManager("RDS Credentials")
    dynamodb = Dynamodb("DynamoDB\nreports")

    # External APIs
    bluesky_api = Firewall("Bluesky API")
    gemini_api = Firewall("Gemini API")

    with Cluster("Event-Driven Pipeline"):
        sqs_events = SQS("CampaignEvents\n.fifo (hi-thru)")

        with Cluster("Orchestration"):
            orchestrator = Lambda("Orchestrator")
            eb_schedules = Eventbridge("EventBridge\nSchedule Group")

        sqs_topics = SQS("CampaignTopics\n.fifo (hi-thru)")

        fetcher = Lambda("Fetcher")

        sns_posts = SNS("CampaignPosts\n.fifo (fan-out)")

        with Cluster("Fan-out Branches"):
            with Cluster("Storage Path"):
                sqs_to_s3 = SQS("PostsToS3\n.fifo")
                s3_saver = Lambda("S3 Saver")

            with Cluster("Analysis Path"):
                sqs_to_analyze = SQS("PostsToAnalyze\n.fifo")
                report_gen = Lambda("ReportGen")

        gemini_secret = SecretsManager("Gemini API Key")

        sqs_reports = SQS("Reports.fifo")
        report_writer = Lambda("ReportWriter")

    with Cluster("Dead Letter Queues (5)"):
        dlq = SQS("5 DLQs\n14d retention")

    logs = Cloudwatch("CloudWatch\n9 Log Groups\n14d retention")

    # ── User-facing flows ────────────────────────────────────────────────────
    user >> Edge(label="GET /*") >> s3_frontend
    user >> Edge(label="/api/auth") >> auth_lambda
    user >> Edge(label="/api/reports") >> reports_lambda
    user >> Edge(label="/api/campaigns") >> campaigns_lambda

    auth_lambda >> Edge(label="JWT claims", style="dashed") >> cognito
    campaigns_lambda >> Edge(label="JWT claims", style="dashed") >> cognito
    reports_lambda >> Edge(label="JWT claims", style="dashed") >> cognito

    # ── VPC internal flows ───────────────────────────────────────────────────
    campaigns_lambda >> Edge(label=":5432") >> rds_proxy
    rds_proxy >> rds_instance
    rds_proxy >> Edge(label=":443", style="dashed") >> vpce_sm
    vpce_sm >> rds_secret
    campaigns_lambda >> Edge(label=":443", style="dashed") >> vpce_sqs
    campaigns_lambda >> Edge(style="dashed") >> vpce_logs

    # ── Reports Lambda → DynamoDB ────────────────────────────────────────────
    reports_lambda >> dynamodb

    # ── Pipeline flow ────────────────────────────────────────────────────────
    campaigns_lambda >> sqs_events
    sqs_events >> orchestrator
    orchestrator >> eb_schedules
    orchestrator >> sqs_topics
    eb_schedules >> sqs_topics
    sqs_topics >> fetcher
    fetcher >> Edge(label="fetch posts", style="bold") >> bluesky_api
    fetcher >> sns_posts

    sns_posts >> sqs_to_s3
    sns_posts >> sqs_to_analyze

    sqs_to_s3 >> s3_saver
    s3_saver >> s3_posts

    sqs_to_analyze >> report_gen
    report_gen >> Edge(label="sentiment analysis", style="bold") >> gemini_api
    report_gen >> Edge(style="dashed") >> gemini_secret
    report_gen >> sqs_reports
    sqs_reports >> report_writer
    report_writer >> dynamodb

    # ── Observability ────────────────────────────────────────────────────────
    auth_lambda >> Edge(style="dotted") >> logs
    orchestrator >> Edge(style="dotted") >> logs
    fetcher >> Edge(style="dotted") >> logs

    # ── DLQ connections (representative) ─────────────────────────────────────
    sqs_events >> Edge(label="maxRcv=3", style="dashed", color="red") >> dlq
    sqs_topics >> Edge(style="dashed", color="red") >> dlq
