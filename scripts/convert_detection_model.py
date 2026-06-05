import os
import sys

os.environ["OMP_NUM_THREADS"] = "1"

OUTPUT_PATH = "models/ObjectDetector.mlpackage"

print("Loading YOLOv8n pretrained model...")
from ultralytics import YOLO

model = YOLO("yolov8n.pt")
print(f"Model loaded: {sum(p.numel() for p in model.model.parameters()):,} parameters")

print("Exporting to Core ML...")
model.export(
    format="coreml",
    imgsz=640,
    half=False,
    nms=True,
)

exported_path = "yolov8n.mlpackage"
if os.path.exists(exported_path):
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    if os.path.exists(OUTPUT_PATH):
        import shutil
        shutil.rmtree(OUTPUT_PATH)
    os.rename(exported_path, OUTPUT_PATH)

file_size_mb = sum(
    os.path.getsize(os.path.join(dp, f))
    for dp, _, fns in os.walk(OUTPUT_PATH)
    for f in fns
) / (1024 * 1024)

print(f"Saved to {OUTPUT_PATH} ({file_size_mb:.1f} MB)")

print("\nValidating Core ML model...")
import coremltools as ct
loaded = ct.models.MLModel(OUTPUT_PATH)
spec = loaded.get_spec()
print("Inputs:")
for inp in spec.description.input:
    print(f"  {inp.name}: {inp.type}")
print("Outputs:")
for out in spec.description.output:
    print(f"  {out.name}: {out.type}")
print("Validation passed.")
