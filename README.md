# Hackmode Security Reconnaissance Framework

A Nextflow-based security reconnaissance automation framework for defensive security research.

## Overview

This framework provides automated workflows for:
- **Passive reconnaissance**: Subdomain enumeration (subfinder, assetfinder)
- **Active reconnaissance**: HTTP probing (httpx), port scanning, directory bruteforcing
- **Asset discovery and management**: BBRF integration with automated upload
- **Modular design**: Separate workflows for passive recon, active recon, and upload

## Requirements

- Nextflow (>=21.10.3)
- Docker or Singularity (optional, for containerized execution)
- Security tools:
  - bbrf
  - subfinder
  - assetfinder
  - httpx
  - jq

## Quick Start

1. **Check tool availability:**
   ```bash
   ./bin/check_tools.sh
   ```

2. **Run with default settings:**
   ```bash
   nextflow run main.nf --bbrf_program your-program-name
   ```

3. **Run with custom input file:**
   ```bash
   nextflow run main.nf --input targets.txt --bbrf_program your-program-name
   ```

4. **Run passive reconnaissance only:**
   ```bash
   nextflow run main.nf --passive_recon --bbrf_program your-program-name
   ```

5. **Run active reconnaissance only:**
   ```bash
   nextflow run main.nf --active_recon --bbrf_program your-program-name
   ```

6. **Run full pipeline (passive + active + upload):**
   ```bash
   nextflow run main.nf --passive_recon --active_recon --upload_to_bbrf --bbrf_program your-program-name
   ```

7. **Run fuzzing/directory busting:**
   ```bash
   nextflow run fuzz.nf --input urls.txt --wordlist /path/to/wordlist.txt
   ```

8. **Test BBRF URL processes:**
   ```bash
   nextflow run test_bbrf_urls.nf --bbrf_program your-program-name
   ```

## Directory Structure

```
.
├── main.nf                 # Main workflow entry point
├── nextflow.config         # Main configuration file
├── nextflow_schema.json    # Parameter schema for validation
├── modules/                # Individual tool modules
│   ├── bbrf.nf
│   ├── subfinder.nf
│   ├── assetfinder.nf
│   ├── httpx.nf
│   ├── gobuster.nf
│   ├── ffuf.nf
│   └── dirbuster.nf
├── subworkflows/           # Reusable workflow components
│   ├── passive_recon.nf
│   ├── active_recon.nf
│   ├── upload.nf
│   └── dirbusting.nf
├── conf/                   # Configuration files
│   ├── base.config
│   └── params.config
├── bin/                    # Helper scripts
│   └── check_tools.sh
├── assets/                 # Static assets
├── legacy/                 # Legacy files (nf/ directory, examples)
├── fuzz.nf                 # Fuzzing/directory busting workflow
├── fuzz.config             # Fuzzing configuration
├── FUZZING.md              # Fuzzing documentation
└── test_bbrf_urls.nf       # Test workflow for BBRF URL processes
```

## Configuration

### Environment Variables

- `HACKMODE_OP`: Operation name (used for BBRF program identification)
- `HACKMODE_PATH`: Base path for operation files and output

### Key Parameters

- `--bbrf_program`: BBRF program name for data storage
- `--use_bbrf_targets`: Load targets from BBRF database
- `--upload_to_bbrf`: Upload results back to BBRF
- `--passive_recon`: Enable passive reconnaissance
- `--active_recon`: Enable active reconnaissance
- `--input`: Input file with targets (alternative to BBRF)
- `--outdir`: Output directory (default: ./results)

### Profiles

- `standard`: Local execution (default)
- `docker`: Docker containerized execution
- `singularity`: Singularity containerized execution
- `cluster`: SLURM cluster execution
- `test`: Test configuration

## Examples

### Basic Usage

```bash
# Set environment variables
export HACKMODE_OP=my-pentest
export HACKMODE_PATH=/path/to/operation

# Run passive reconnaissance
nextflow run main.nf --passive_recon
```

### Advanced Usage

```bash
# Run with custom parameters
nextflow run main.nf \\
    --bbrf_program my-program \\
    --passive_recon \\
    --httpx_threads 100 \\
    --upload_to_bbrf \\
    --outdir results/
```

### Using Docker

```bash
nextflow run main.nf -profile docker --bbrf_program my-program
```

## Output

Results are organized in the output directory:
- `bbrf/`: BBRF upload logs
- `subfinder/`: Subdomain enumeration results
- `assetfinder/`: Asset discovery results
- `httpx/`: HTTP probing results
- `pipeline_info/`: Execution reports and logs

## Development

### Adding New Tools

1. Create a new module in `modules/tool_name.nf`
2. Add the tool to the appropriate subworkflow
3. Update the configuration and schema
4. Add tool check to `bin/check_tools.sh`

### Testing

```bash
# Run with test profile
nextflow run main.nf -profile test

# Validate parameters
nextflow run main.nf --validate_params
```


## License

This project is licensed under the MIT License - see the LICENSE file for details.
