import os
import json
import numpy as np
from qiskit.qasm3 import loads
from qiskit.quantum_info import SparsePauliOp
from qrmi import QRMI, EstimatorV2


data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "isa_circuit.qasm")) as f:
    qc = loads(f.read())

with open(os.path.join(data_folder, "isa_obs.json")) as f:
    obs = SparsePauliOp.from_operator(json.load(f))

with open(os.path.join(data_folder, "parameters.json")) as f:
    parameter_values = json.load(f)

qrmi = QRMI()
resources = qrmi.resources()
quantum_resource = resources[0]

estimator = EstimatorV2(quantum_resource)
job = estimator.run([(qc, obs, parameter_values)])
print(f"Job ID: {job.job_id()}")

result = job.result()
expectation_value = result[0].data.evs
expectation_value_stds = result[0].data.stds
print(f"Expectation Value: {expectation_value}")
