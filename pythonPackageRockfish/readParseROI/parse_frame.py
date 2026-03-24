import math

def parse_frame(frame_idx, frame_bin):
    n_chunk = math.ceil(len(frame_idx) / frame_bin)
    return [
        frame_idx[i*frame_bin:(i+1)*frame_bin]
        for i in range(n_chunk)
    ]
