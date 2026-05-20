# Architecture Diagrams

Two approaches for generating AWS architecture diagrams.

## Prerequisites

```bash
pip install diagrams
sudo apt install graphviz   # Debian/Ubuntu
# or: brew install graphviz  # macOS
```

## Presentable Diagram (diagrams library)

Hand-crafted with logical clustering and clean data flow. Best for docs and presentations.

```bash
cd terraform/diagrams/
python generate.py
```

Outputs `marky-architecture.png` in this directory.

## Auto-Generated Diagram (Terravision)

Auto-generated from `.tf` source files. Complete but noisy — useful as a reference for auditing all resources.

```bash
pip install terravision

cd terraform/
terravision draw --source . --format png --outfile diagrams/marky-raw
terravision draw --source . --format png --outfile diagrams/marky-raw --annotate diagrams/terravision.yml
terravision draw --source . --format png --outfile diagrams/marky-simplified --simplified
```

Output files include a provider suffix and `.dot.` infix (e.g., `marky-raw-aws.dot.png`).

## When to Use What

| Diagram | Use Case | Maintainability |
|---------|----------|-----------------|
| `generate.py` | Presentations, docs, onboarding | Manual — update when architecture changes |
| Terravision | Audit, completeness check | Automatic — always reflects current `.tf` files |
