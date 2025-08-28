import os
import json
from qiskit import qpy
from qiskit.primitives import BitArray
from qrmi import QRMI, SamplerV2 as Sampler


data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "isa_circuits.qpy"), "rb") as f:
    isa_circuits = qpy.load(f)


qrmi = QRMI()
resources = qrmi.resources()
quantum_resource = resources[0]

# Sample from the circuits
noisy_sampler = Sampler(quantum_resource)
job = noisy_sampler.run(isa_circuits, shots=500)

# Combine the counts from the individual Trotter circuits
bit_array = BitArray.concatenate_shots([result.data.meas for result in job.result()])

counts = bit_array.get_counts()

with open(os.path.join(data_folder, "counts.json"), "w") as f:
    json.dump(counts, f)

print(counts)
