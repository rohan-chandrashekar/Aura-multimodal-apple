import torch
import coremltools as ct
import numpy as np
from denoiser import pretrained

SAMPLE_RATE = 16000
CHUNK_SECONDS = 4
CHUNK_SAMPLES = SAMPLE_RATE * CHUNK_SECONDS
OUTPUT_PATH = "models/SpeechEnhancer.mlpackage"

print("Loading pretrained DNS48 model...")
model = pretrained.dns48()
model.eval()

print(f"Model parameters: {sum(p.numel() for p in model.parameters()):,}")

dummy_input = torch.randn(1, 1, CHUNK_SAMPLES)

print("Tracing model...")
with torch.no_grad():
    traced = torch.jit.trace(model, dummy_input)

print("Verifying trace...")
with torch.no_grad():
    original_out = model(dummy_input)
    traced_out = traced(dummy_input)
    max_diff = (original_out - traced_out).abs().max().item()
    print(f"Trace verification — max abs diff: {max_diff:.2e}")

print("Converting to Core ML...")
mlmodel = ct.convert(
    traced,
    inputs=[ct.TensorType(name="audio", shape=(1, 1, CHUNK_SAMPLES))],
    outputs=[ct.TensorType(name="enhanced")],
    minimum_deployment_target=ct.target.macOS14,
)

mlmodel.author = "Facebook Research (pretrained DNS48)"
mlmodel.short_description = (
    "Demucs-based speech enhancement model. "
    f"Input: {CHUNK_SECONDS}s mono audio at {SAMPLE_RATE} Hz. "
    "Output: enhanced audio, same shape."
)

import os
os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
mlmodel.save(OUTPUT_PATH)

file_size_mb = sum(
    os.path.getsize(os.path.join(dp, f))
    for dp, _, fns in os.walk(OUTPUT_PATH)
    for f in fns
) / (1024 * 1024)

print(f"Saved to {OUTPUT_PATH} ({file_size_mb:.1f} MB)")

print("\nValidating Core ML model...")
import coremltools as ct
loaded = ct.models.MLModel(OUTPUT_PATH)
test_input = np.random.randn(1, 1, CHUNK_SAMPLES).astype(np.float32)
result = loaded.predict({"audio": test_input})
out_shape = result["enhanced"].shape
print(f"Core ML output shape: {out_shape}")
assert out_shape == (1, 1, CHUNK_SAMPLES), f"Shape mismatch: expected (1, 1, {CHUNK_SAMPLES}), got {out_shape}"
print("Validation passed.")
