FRAME_W = 640
FOV = 1
"""Horizontal FOV in radians."""


def to_fixedp(x):
    """Express a real number as Q8.16 fixed point.
    """
    neg = x < 0
    x = abs(x)
    x = int(x * (1 << 16))
    if neg:
        x = (1 << 24) - x
    return f"0x {x:06x}"


def to_real(s):
    """Express fixed point as real.
    s: Length 6 hex for Q8.16 fp.
    """
    x = int(s, 16)
    if x >= 0x800000:
        x = (1 << 24) - x
        x *= -1
    return x / (1 << 16)


def compute_fov():
    """Compute angle per pixel (at frame center).
    """
    px_angle = FOV / FRAME_W
    print(px_angle)
    print(to_fixedp(px_angle))


if __name__ == "__main__":
    compute_fov()
