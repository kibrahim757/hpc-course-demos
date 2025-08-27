from mpi4py import MPI
import sys

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

sys.stdout.write(f"[Rank {rank}] Hello from process {rank} of {size}!\n")

if rank == 0:
    data = {'answer': 42, 'pi': 3.14}
    sys.stdout.write(f"[Rank {rank}] Sending: {data}\n")
    comm.send(data, dest=1, tag=42)
elif rank == 1:
    data = comm.recv(source=0, tag=42)
    sys.stdout.write(f"[Rank {rank}] Received: {data}\n")
