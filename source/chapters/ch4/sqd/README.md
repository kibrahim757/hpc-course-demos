MAPPING_JOB=$(sbatch --parsable mapping.sh)
OPTIMIZE_JOB=$(sbatch --parsable --dependency=afterok:$MAPPING_JOB optimization.sh)
EXECUTE_JOB=$(sbatch --parsable --dependency=afterok:$OPTIMIZE_JOB execution.sh)
POSTPROCESSING_JOB=$(sbatch --parsable --dependency=afterok:$EXECUTE_JOB postprocessing.sh)
watch squeue
