"""Patch onnx2tf Slice.py to handle TF 2.21 tuple shapes."""
import os

filepath = os.path.join(
    os.path.dirname(__file__),
    '.venv_convert/lib/python3.12/site-packages/onnx2tf/ops/Slice.py'
)

with open(filepath, 'r') as f:
    content = f.read()

old_block = """    input_tensor_shape = input_tensor.shape
    input_tensor_shape_list = input_tensor_shape.as_list() \\
        if input_tensor_shape.rank is not None else None
    input_tensor_rank = int(input_tensor_shape.rank) if input_tensor_shape.rank is not None else 1"""

new_block = """    input_tensor_shape = input_tensor.shape
    if hasattr(input_tensor_shape, 'rank') and input_tensor_shape.rank is not None:
        input_tensor_shape_list = input_tensor_shape.as_list()
        input_tensor_rank = int(input_tensor_shape.rank)
    elif isinstance(input_tensor_shape, (tuple, list)):
        input_tensor_shape_list = list(input_tensor_shape)
        input_tensor_rank = len(input_tensor_shape)
    else:
        input_tensor_shape_list = None
        input_tensor_rank = 1"""

if old_block in content:
    content = content.replace(old_block, new_block)
    print("PATCHED: Line 83-90 block")
else:
    print("WARNING: Block 1 NOT FOUND in file")
    # Debug: show what we're looking for vs what's there
    with open(filepath, 'r') as f2:
        lines = f2.readlines()
    for i, line in enumerate(lines):
        if 'input_tensor_shape' in line:
            print(f'  File line {i+1}: {repr(line.rstrip())}')

# Fix line ~656
old_block2 = """            check_output_shape = output_tensor_shape.as_list() \\
                if output_tensor_shape.rank is not None else None"""

new_block2 = """            if hasattr(output_tensor_shape, 'rank') and output_tensor_shape.rank is not None:
                check_output_shape = output_tensor_shape.as_list()
            elif isinstance(output_tensor_shape, (tuple, list)):
                check_output_shape = list(output_tensor_shape)
            else:
                check_output_shape = None"""

if old_block2 in content:
    content = content.replace(old_block2, new_block2)
    print("PATCHED: Line 656 block")
else:
    print("WARNING: Block 2 NOT FOUND")

# Fix line ~669
old_block3 = """            elif input_tensor.shape.rank is not None:"""

new_block3 = """            elif (hasattr(input_tensor.shape, 'rank') and input_tensor.shape.rank is not None) or isinstance(input_tensor.shape, (tuple, list)):"""

if old_block3 in content:
    content = content.replace(old_block3, new_block3)
    print("PATCHED: Line 669 block")
else:
    print("WARNING: Block 3 NOT FOUND")

with open(filepath, 'w') as f:
    f.write(content)

print("\nDone!")
