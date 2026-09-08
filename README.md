# DebugRenderer

A utility for Advanced visually debugging Angel Script logic in Portal 2 Community Edition.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d0844428-a57b-410a-9dd0-413567d33c8c" />

## Possibilities

### Basic primitives
- `OBox`,
- `PlaneWire`, `PlaneSolid`
- `Arc`, `ArcBetween`, `Disk`
- `Hemisphere`, `CappedHemisphere`
- `Cylinder`, `CappedCylinder`, `CapsuleHemi`
- `Tube`, `Torus`, `Helix`
- `Pyramid`, `Tetrahedron`, `Prism`
- `Frustum` / `SimpleFrustum`

### Arrows and vectors
- `Arrow`, `DoubleArrow`, `ThickArrow`, `DoubleThickArrow`
- `VelocityArrow`, `AccelerationArrow`, `VelocityAccelerationArrows`


## Installation and Use

1. Copy `DebugRenderer.as` in 'p2ce/code/'.
2. Include it in your script:

```as
#include "DebugRenderer.as"

class CMyEntity : CBaseEntity
{

    void Spawn()
    {
    }

    void Think()
    {
        debug::Line(...)
    }
}
```

# Licence
You are free to use, modify and share this library under the terms of the MIT License. The only condition is keeping the copyright notice, and stating whether or not the code was modified. 
See LICENSE for details.

