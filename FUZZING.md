# Fuzzing and Directory Busting Workflow

A specialized Nextflow workflow for web application fuzzing and directory busting.

## Overview

The `fuzz.nf` workflow provides comprehensive directory busting and fuzzing capabilities using multiple tools:

- **Gobuster**: Fast directory/file enumeration
- **FFUF**: Fast web fuzzer with advanced features
- **DirBuster**: Traditional directory busting (via dirb)

## Features

### Core Functionality
- **Directory Enumeration**: Discover hidden directories and files
- **Virtual Host Discovery**: Find additional vhosts
- **Parameter Fuzzing**: Discover GET/POST parameters
- **Batch Processing**: Handle multiple URLs efficiently
- **BBRF Integration**: Load targets from and upload results to BBRF

### Advanced Features
- **Multiple Tools**: Run gobuster, ffuf, and dirbuster in parallel
- **Custom Wordlists**: Use your own wordlists
- **Flexible Extensions**: Configure file extensions to search for
- **Rate Limiting**: Avoid overwhelming targets
- **Result Deduplication**: Automatically remove duplicates

## Quick Start

### Prerequisites

```bash
# Check tool availability
./bin/check_tools.sh

# Install fuzzing tools if missing
# Ubuntu/Debian:
sudo apt install gobuster dirb
go install github.com/ffuf/ffuf@latest

# Or using package managers like brew, yum, etc.
```

### Basic Usage

```bash
# Fuzz URLs from a file
nextflow run fuzz.nf --input urls.txt --wordlist /path/to/wordlist.txt

# Use BBRF as source
nextflow run fuzz.nf --use_bbrf_urls --bbrf_program my-program --wordlist /path/to/wordlist.txt

# Custom configuration
nextflow run fuzz.nf --input urls.txt --wordlist /path/to/wordlist.txt --threads 100 --extensions php,html,js
```

## Configuration

### Core Parameters

- `--input`: Input file with URLs (one per line)
- `--wordlist`: Path to wordlist file
- `--outdir`: Output directory (default: ./fuzz_results)
- `--threads`: Number of threads (default: 50)
- `--extensions`: File extensions to fuzz (default: php,html,txt,js,json,xml,asp,aspx,jsp)
- `--timeout`: Request timeout (default: 10s)

### Tool Selection

- `--use_gobuster`: Enable gobuster (default: true)
- `--use_ffuf`: Enable ffuf (default: true)
- `--use_dirbuster`: Enable dirbuster (default: false)

### Advanced Options

- `--use_gobuster_vhost`: Enable gobuster vhost discovery
- `--use_ffuf_vhost`: Enable ffuf vhost discovery
- `--use_ffuf_params`: Enable ffuf parameter fuzzing
- `--batch_size`: URLs per batch (default: 100)
- `--max_depth`: Maximum recursion depth (default: 3)

### BBRF Integration

- `--use_bbrf_urls`: Load URLs from BBRF database
- `--bbrf_program`: BBRF program name
- `--upload_to_bbrf`: Upload results to BBRF

## Profiles

### Fast Profile
```bash
nextflow run fuzz.nf -c fuzz.config -profile fast --input urls.txt --wordlist /path/to/wordlist.txt
```
- 100 threads
- 5s timeout
- Limited extensions
- Gobuster and FFUF only

### Thorough Profile
```bash
nextflow run fuzz.nf -c fuzz.config -profile thorough --input urls.txt --wordlist /path/to/wordlist.txt
```
- 25 threads
- 30s timeout
- Extensive extensions
- All tools enabled
- Vhost and parameter fuzzing
- Recursive scanning

### Stealth Profile
```bash
nextflow run fuzz.nf -c fuzz.config -profile stealth --input urls.txt --wordlist /path/to/wordlist.txt
```
- 10 threads
- 15s timeout
- 1s delay between requests
- Limited concurrent targets

## Examples

### Basic Directory Busting
```bash
# Simple directory busting
nextflow run fuzz.nf \\
    --input urls.txt \\
    --wordlist ~/wordlists/common.txt \\
    --threads 50

# With custom extensions
nextflow run fuzz.nf \\
    --input urls.txt \\
    --wordlist ~/wordlists/big.txt \\
    --extensions php,html,js,json,xml,backup,bak
```

### BBRF Integration
```bash
# Load URLs from BBRF and upload results
nextflow run fuzz.nf \\
    --use_bbrf_urls \\
    --bbrf_program my-pentest \\
    --upload_to_bbrf \\
    --wordlist ~/wordlists/common.txt

# Use specific BBRF program
export HACKMODE_OP=my-pentest
nextflow run fuzz.nf \\
    --use_bbrf_urls \\
    --wordlist ~/wordlists/common.txt
```

### Advanced Fuzzing
```bash
# Comprehensive fuzzing with all features
nextflow run fuzz.nf \\
    --input urls.txt \\
    --wordlist ~/wordlists/big.txt \\
    --use_gobuster \\
    --use_ffuf \\
    --use_dirbuster \\
    --use_ffuf_params \\
    --use_ffuf_vhost \\
    --threads 25 \\
    --timeout 30s \\
    --extensions php,html,js,json,xml,asp,aspx,jsp,backup,bak,old,orig
```

### Batch Processing
```bash
# Process large URL lists in batches
nextflow run fuzz.nf \\
    --input large_urls.txt \\
    --wordlist ~/wordlists/common.txt \\
    --batch_size 50 \\
    --threads 25
```

## Output Structure

Results are organized in the output directory:
```
fuzz_results/
├── gobuster/
│   ├── gobuster_example_com.txt
│   └── gobuster_example_com_found.txt
├── ffuf/
│   ├── ffuf_example_com.json
│   └── ffuf_example_com_found.txt
├── dirbuster/
│   ├── dirbuster_example_com.txt
│   └── dirbuster_example_com_found.txt
└── combined_dirbusting_results.txt
```

## Wordlists

### Recommended Wordlists
- **SecLists**: https://github.com/danielmiessler/SecLists
- **FuzzDB**: https://github.com/fuzzdb-project/fuzzdb
- **Dirbuster Lists**: Built-in wordlists

### Common Locations
```bash
# SecLists
~/wordlists/SecLists/Discovery/Web-Content/common.txt
~/wordlists/SecLists/Discovery/Web-Content/big.txt
~/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt

# Custom wordlists
~/wordlists/custom/
```

## Integration with Main Pipeline

The fuzzing workflow is separate from the main recon pipeline and can be run independently:

```bash
# Run main recon pipeline first
nextflow run main.nf --passive_recon --active_recon --bbrf_program my-program

# Then run fuzzing on discovered URLs
nextflow run fuzz.nf --use_bbrf_urls --bbrf_program my-program --wordlist ~/wordlists/common.txt
```

## Performance Tuning

### For Fast Results
- Use smaller wordlists
- Increase thread count
- Reduce timeout
- Limit extensions
- Use gobuster only

### For Comprehensive Results
- Use larger wordlists
- Enable all tools
- Enable vhost/parameter fuzzing
- Increase timeout
- Use recursive scanning

### For Stealth
- Reduce thread count
- Increase delays
- Use realistic user agents
- Limit concurrent targets

## Troubleshooting

### Common Issues

1. **Rate Limiting**: Reduce threads, increase delays
2. **Timeouts**: Increase timeout values
3. **Memory Issues**: Reduce batch size, limit concurrent processes
4. **False Positives**: Adjust filtering options

### Tool-Specific Issues

- **Gobuster**: Check wordlist format, ensure proper permissions
- **FFUF**: Verify JSON output is enabled for proper parsing
- **DirBuster**: Ensure dirb is installed and accessible

## Security Considerations

- Only use against systems you own or have permission to test
- Respect rate limits and robots.txt
- Use appropriate delays to avoid overwhelming targets
- Monitor resource usage on both client and target systems