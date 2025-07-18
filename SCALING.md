# Scaling Configuration Guide

This document explains how to scale the Hackmode reconnaissance pipeline across different environments.

## Quick Start

### Local Docker Scaling
```bash
# Build the container
docker build -t hackmode/recon:latest .

# Run with Docker profile (moderate scaling)
nextflow run main.nf -profile docker --passive_recon --active_recon --web_crawl --bbrf_program my-program

# Run with high-performance scaling
nextflow run main.nf -profile scale_out --passive_recon --active_recon --web_crawl --bbrf_program my-program
```

### Docker Compose (Local Cluster)
```bash
# Start the stack
docker-compose up -d

# Run pipeline in the container
docker-compose exec nextflow bash
nextflow run main.nf -profile docker_swarm --passive_recon --active_recon --web_crawl --bbrf_program my-program
```

### Kubernetes Scaling
```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Run pipeline in Kubernetes
kubectl exec -it deployment/hackmode-nextflow -n hackmode-recon -- bash
nextflow run main.nf -profile kubernetes --passive_recon --active_recon --web_crawl --bbrf_program my-program
```

## Scaling Profiles

### 1. Docker Profile
- **Queue Size**: 100 concurrent jobs
- **Submit Rate**: 50 jobs/minute
- **Best For**: Single machine with 4-8 cores

```bash
nextflow run main.nf -profile docker --web_crawl --bbrf_program my-program
```

### 2. Docker Swarm Profile
- **Queue Size**: 500 concurrent jobs
- **Submit Rate**: 100 jobs/minute
- **Best For**: Docker Swarm cluster

```bash
nextflow run main.nf -profile docker_swarm --web_crawl --bbrf_program my-program
```

### 3. Kubernetes Profile
- **Queue Size**: 1000 concurrent jobs
- **Submit Rate**: 200 jobs/minute
- **Best For**: Kubernetes cluster with auto-scaling

```bash
nextflow run main.nf -profile kubernetes --web_crawl --bbrf_program my-program
```

### 4. AWS Batch Profile
- **Queue Size**: 2000 concurrent jobs
- **Submit Rate**: 500 jobs/minute
- **Best For**: Large-scale cloud operations

```bash
nextflow run main.nf -profile aws_batch --web_crawl --bbrf_program my-program
```

### 5. Scale Out Profile
- **Queue Size**: 1000 concurrent jobs
- **Submit Rate**: 500 jobs/minute
- **MaxForks**: HTTPx (50), Katana (25)
- **Best For**: High-performance local systems

```bash
nextflow run main.nf -profile scale_out --web_crawl --bbrf_program my-program
```

## Resource Configuration

### Per-Process Resource Allocation

| Process | Docker | Kubernetes | AWS Batch |
|---------|--------|------------|-----------|
| HTTPX   | 2 CPU, 2GB, 50 forks | 2 CPU, 3GB, 200 forks | 4 CPU, 4GB |
| KATANA  | 1 CPU, 4GB, 25 forks | 2 CPU, 6GB, 100 forks | 2 CPU, 8GB |
| SUBFINDER | 1 CPU, 1GB, 20 forks | 1 CPU, 2GB, 50 forks | 2 CPU, 2GB |

### Scaling Metrics

| Profile | Max Concurrent | Targets/Hour | Memory Usage |
|---------|---------------|--------------|--------------|
| Docker | 100 | ~1,000 | 8-16GB |
| Docker Swarm | 500 | ~5,000 | 40-80GB |
| Kubernetes | 1000 | ~10,000 | 100-200GB |
| AWS Batch | 2000 | ~20,000 | Auto-scaling |

## Cloud Deployments

### AWS Batch Setup
1. Create ECR repository and push image
2. Create Batch compute environment
3. Create job queue: `hackmode-recon-queue`
4. Update profile with your account details

### GCP Batch Setup
1. Push image to GCR
2. Enable Batch API
3. Update profile with project details

### Kubernetes Setup
1. Apply manifests: `kubectl apply -f k8s/`
2. Configure storage class for your cluster
3. Add node labels for workload placement

## Monitoring

### Container Metrics
```bash
# View resource usage
docker stats

# Kubernetes monitoring
kubectl top pods -n hackmode-recon
```

### Pipeline Monitoring
- Reports: `results/execution_report.html`
- Timeline: `results/execution_timeline.html` 
- Trace: `results/execution_trace.txt`

### Optional Monitoring Stack
```bash
# Start monitoring (Prometheus + Grafana)
docker-compose --profile monitoring up -d

# Access Grafana: http://localhost:3000
# Username: admin, Password: hackmode123
```

## Performance Tuning

### Optimize for Target Count
- **< 100 targets**: Use `standard` profile
- **100-1000 targets**: Use `docker` profile
- **1000-10000 targets**: Use `kubernetes` profile
- **> 10000 targets**: Use `aws_batch` profile

### Optimize for Infrastructure
- **Single machine**: `docker` or `scale_out`
- **Multiple machines**: `docker_swarm` or `cluster`
- **Cloud**: `kubernetes`, `aws_batch`, or `gcp_batch`

### Rate Limiting Considerations
- Respect target rate limits
- Use `katana_delay` and `katana_rate_limit` parameters
- Adjust `submitRateLimit` in profiles

## Troubleshooting

### Common Issues
1. **Out of Memory**: Reduce `maxForks` or increase container memory
2. **Rate Limiting**: Increase delays between requests
3. **Network Issues**: Configure DNS settings in Docker profiles
4. **Permission Issues**: Check service account permissions in Kubernetes

### Debug Mode
```bash
# Enable debug logging
nextflow run main.nf -profile docker --web_crawl --bbrf_program my-program -with-trace
```

## Security Considerations

1. **Network Isolation**: Use dedicated networks/namespaces
2. **Resource Limits**: Set appropriate CPU/memory limits
3. **Secrets Management**: Use Kubernetes secrets or Docker secrets
4. **Non-root Containers**: All containers run as non-root user (UID 1000)
5. **Read-only Filesystems**: Where possible, use read-only mounts

## Custom Scaling

### Environment Variables
- `HACKMODE_OP`: Operation name
- `HACKMODE_PATH`: Base path for operations
- `NXF_WORK`: Nextflow work directory

### Custom Profile Example
```groovy
profiles {
    custom_scale {
        process.executor = 'local'
        executor {
            queueSize = 200
            submitRateLimit = '100/1min'
        }
        
        process {
            withName: 'HTTPX.*' {
                maxForks = 30
                cpus = 1
                memory = '1 GB'
            }
        }
    }
}
```

Use with: `nextflow run main.nf -profile custom_scale`