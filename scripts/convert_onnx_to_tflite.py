#!/usr/bin/env python3
"""
Convert Kokoro-82M ONNX model to TFLite format for on-device inference.

Usage:
    pip install onnx2tf onnxruntime tensorflow
    python scripts/convert_onnx_to_tflite.py [--quantize] [--input MODEL.onnx] [--output MODEL.tflite]

Requirements:
    - onnx2tf    (https://github.com/PINTO0309/onnx2tf)
    - onnxruntime
    - tensorflow >= 2.13

If --quantize is set, the output will be FP16 quantized (smaller, slightly less precise).
"""

import argparse
import os
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description="Convert Kokoro ONNX → TFLite")
    parser.add_argument("--input", default="model_quantized.onnx",
                        help="Path to the Kokoro ONNX model file")
    parser.add_argument("--output", default="kokoro-82m.tflite",
                        help="Output TFLite file path")
    parser.add_argument("--quantize", action="store_true",
                        help="Apply FP16 quantization (reduces size ~50%%)")
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"❌ Input file not found: {args.input}")
        print("   Download the ONNX model from HuggingFace first:")
        print("   https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/model_quantized.onnx")
        sys.exit(1)

    print(f"🔄 Converting {args.input} → {args.output}")

    # Build onnx2tf command
    cmd = [
        "onnx2tf",
        "-i", args.input,
        "-o", "tflite_tmp",
        "--output_tflite", args.output,
    ]

    if args.quantize:
        cmd.extend(["--quantization_type", "FP16"])

    try:
        subprocess.run(cmd, check=True)
        print(f"✅ Conversion complete: {args.output}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Conversion failed: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("❌ 'onnx2tf' not found. Install it:")
        print("   pip install onnx2tf onnxruntime tensorflow")
        sys.exit(1)
    finally:
        # Cleanup temp dir
        import shutil
        shutil.rmtree("tflite_tmp", ignore_errors=True)

    # Show file sizes
    orig_size = os.path.getsize(args.input)
    tflite_size = os.path.getsize(args.output)
    print(f"\n📊 Size comparison:")
    print(f"   ONNX:   {orig_size / 1024 / 1024:.1f} MB")
    print(f"   TFLite: {tflite_size / 1024 / 1024:.1f} MB")
    print(f"   Ratio:  {tflite_size / orig_size * 100:.1f}%")

    print("\n📱 Copy the .tflite file to your device:")
    print(f"   Android: /storage/emulated/0/Android/data/com.eburon.edge/files/EburonEdge/models/tts/")
    print(f"   iOS:     On your device via iTunes File Sharing or the app's documents directory")
    print(f"   Desktop: <app>/../Shared/models/tts/")


if __name__ == "__main__":
    main()
