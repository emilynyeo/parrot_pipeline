# Resource Usage Guide

## How to Run the Pipeline

```bash
# Make sure the script is executable
chmod +x run_full_pipeline_local.sh

# Run it
./run_full_pipeline_local.sh
```

Or if you prefer:
```bash
bash run_full_pipeline_local.sh
```

## Current Configuration (Sequential Mode)

With your current settings:
- **PARALLEL_JOBS = 3**
- **RUN_MODE = "sequential"**

### What Will Happen:

1. **Runs one model type at a time** (8 model types total)
2. **Within each model type, runs 3 models in parallel**
3. **Each model type has 100 seeds** (but you changed cv_times to 20, so faster)

### Resource Usage:

**CPU Cores:**
- **Maximum cores used: 3** (since PARALLEL_JOBS=3)
- Your system has 8 cores, so you're using 37.5% of capacity
- This leaves plenty of headroom for other tasks

**Memory (RAM):**
- **Per model: ~500 MB - 2 GB** (depends on dataset size and model type)
- **With 3 parallel jobs: ~1.5 - 6 GB** maximum
- Your system has 16 GB, so you're using ~10-40% of capacity
- Very safe!

**Disk Space:**
- **Per model file: ~1-5 MB**
- **Total for 800 models: ~800 MB - 4 GB**
- Plus performance files: ~1-2 MB each

### Timeline (Sequential Mode):

- **Per model**: ~1-3 minutes (with cv_times=20)
- **Per model type** (100 seeds): ~100-300 minutes (1.7-5 hours)
- **All 8 model types**: ~13-40 hours total
- **With 3 parallel jobs**: ~4-13 hours total

## If You Switch to Parallel Mode

If you change `RUN_MODE="parallel"`:

**CPU Cores:**
- **Maximum cores used: 24** (3 jobs × 8 model types)
- Your system has 8 cores, so this would be **300% over capacity!**
- **NOT RECOMMENDED** - would cause severe slowdown

**Memory:**
- **Maximum: ~12-48 GB** (3 × 8 × 0.5-2 GB)
- Your system has 16 GB, so this could **exceed your RAM**
- **NOT RECOMMENDED**

## Recommended Settings for Your System

**Your system: 8 cores, 16 GB RAM**

### Option 1: Current (Sequential, Safe) ✅
- `PARALLEL_JOBS=3`
- `RUN_MODE="sequential"`
- Uses: 3 cores, ~1.5-6 GB RAM
- Time: ~4-13 hours

### Option 2: More Aggressive (Still Safe)
- `PARALLEL_JOBS=4`
- `RUN_MODE="sequential"`
- Uses: 4 cores, ~2-8 GB RAM
- Time: ~3-10 hours

### Option 3: Maximum (Use with Caution)
- `PARALLEL_JOBS=6`
- `RUN_MODE="sequential"`
- Uses: 6 cores, ~3-12 GB RAM
- Time: ~2-7 hours
- **Warning**: May slow down other applications

## Monitoring While Running

### Check CPU usage:
```bash
top
# or
htop  # if installed
```

### Check memory usage:
```bash
top -l 1 | grep "PhysMem"
```

### Check progress:
```bash
# Count completed models
ls processed_data/*_miseq_*.Rds | wc -l
ls processed_data/*_nanopore_*.Rds | wc -l

# See latest files
ls -lt processed_data/*.Rds | head -10
```

### Check if processes are running:
```bash
ps aux | grep run_split.R
```

## Stopping and Resuming

- **Press Ctrl+C** to stop gracefully
- **Completed models are saved** - won't be rerun
- **To resume**: Just run the script again - it will skip completed models

## Summary

With your current settings (`PARALLEL_JOBS=3`, `RUN_MODE="sequential"`):
- ✅ **Very safe** - uses only 3 cores and ~1.5-6 GB RAM
- ✅ **Won't overwhelm your system**
- ✅ **Can still use your computer** for other tasks
- ⏱️ **Takes ~4-13 hours** to complete all 800 models

