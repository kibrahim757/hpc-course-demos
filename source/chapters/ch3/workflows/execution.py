import os
import json
import numpy as np
from dotenv import load_dotenv

from qiskit.qasm3 import loads
from qiskit.quantum_info import SparsePauliOp
from qrmi.primitives import QRMIService
from qrmi.primitives.ibm import EstimatorV2, get_target


load_dotenv()
service = QRMIService()

data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "isa_circuit.qasm")) as f:
    qc = loads(f.read())

with open(os.path.join(data_folder, "isa_obs.json")) as f:
    obs = SparsePauliOp.from_operator(json.load(f))

with open(os.path.join(data_folder, "parameters.json")) as f:
    parameter_values = json.load(f)

resources = service.resources()
if len(resources) == 0:
    raise ValueError("No quantum resource is available.")

qrmi = resources[0]
target = get_target(qrmi)

options = {}
estimator = EstimatorV2(qrmi, options=options)
job = estimator.run([(qc, obs, parameter_values)])
print(f"Job ID: {job.job_id()}")

result = job.result()
expectation_value = result[0].data.evs
expectation_value_stds = result[0].data.stds
print(f"Expectation Value: {expectation_value}")
