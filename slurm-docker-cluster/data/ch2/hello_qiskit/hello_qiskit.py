import os
import numpy as np
from qiskit.circuit.library import PauliTwoDesign
from qiskit.quantum_info import SparsePauliOp
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager
from qrmi import QRMI, EstimatorV2

from utils.env import NUM_QUBITS

# Map problem
num_qubits=os.environ.get("NUM_QUBITS", NUM_QUBITS)
qc = PauliTwoDesign(num_qubits=num_qubits,reps=4, seed=5, insert_barriers=True)
parameters = qc.parameters
obs = SparsePauliOp.from_sparse_list([("Z", [num_qubits-2], 1)], num_qubits=num_qubits)

phi_max = 0.5 * np.pi
parameter_values = np.random.uniform(-1 * phi_max, phi_max, len(parameters))

qrmi = QRMI()
resources = qrmi.resources()
quantum_resource = resources[0]

target = quantum_resource.target

# Optimize
pm = generate_preset_pass_manager(
        target=target, 
        optimization_level=1
      )
t_qc = pm.run(qc)
t_obs = obs.apply_layout(t_qc.layout)

# Execute
estimator = EstimatorV2(quantum_resource)
job = estimator.run([(t_qc, t_obs, parameter_values)])
print(f"Job ID: {job.job_id()}")

# Postprocess
result = job.result()
expectation_value = result[0].data.evs
expectation_value_stds = result[0].data.stds
print(f"Expectation Value: {expectation_value}")
