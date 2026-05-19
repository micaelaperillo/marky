package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Campaign struct {
	ID     pgtype.UUID `json:"id"`
	Topics []string    `json:"topics"`
}

var pool *pgxpool.Pool
var queue *sqs.Client

func init() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		panic(err)
	}

	queue = sqs.NewFromConfig(cfg)

	pool, err = pgxpool.New(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		panic(err)
	}
}

func handler(ctx context.Context, event events.CloudWatchEvent) error {
	campaigns, err := getActiveCampaigns(ctx)
	if err != nil {
		return err
	}

	return addToQueue(ctx, campaigns)
}

func getActiveCampaigns(ctx context.Context) ([]Campaign, error) {
	rows, err := pool.Query(ctx, `
		SELECT id, topics
		FROM campaigns
		WHERE end_date > NOW()
	`)

	if err != nil {
		return nil, fmt.Errorf("Upsi: %w", err)
	}

	campaigns, err := pgx.CollectRows(rows, pgx.RowToStructByPos[Campaign])
	if err != nil {
		return nil, fmt.Errorf("Upsi: %w", err)
	}

	return campaigns, nil
}

func addToQueue(ctx context.Context, campaigns []Campaign) error {
	var wg sync.WaitGroup
	defer wg.Wait()

	length := len(campaigns)
	for i := 0; i < length; i += 10 {
		wg.Go(func() {
			if err := sendBatch(ctx, campaigns[i:min(length, i+10)]); err != nil {
				log.Println(fmt.Errorf("Upsi: %w", err))
			}
		})
	}

	return nil
}

func sendBatch(ctx context.Context, cmps []Campaign) error {
	var entries []types.SendMessageBatchRequestEntry
	for c := range cmps {
		b, err := json.Marshal(c)

		if err != nil {
			log.Println(fmt.Errorf("Upsi: %w", err))
			continue
		}

		str := string(b)
		entries = append(entries, types.SendMessageBatchRequestEntry{
			MessageBody: &str,
		})
	}

	_, err := queue.SendMessageBatch(ctx, &sqs.SendMessageBatchInput{
		Entries: entries,
	})

	return err
}

func main() {
	lambda.Start(handler)
}
