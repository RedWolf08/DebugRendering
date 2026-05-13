# DebugRenderer

A utility for visually debugging Angel Script logic in Portal 2 Community Edition.

It allows you to quickly draw any basic shapes in the world: lines, arrows, geometric shapes, text, paths, frustums, and etc.

## Possibilities

### Basic primitives
- `Line`, `Cross`, `Box`, `OBox`, `Grid`
- `Plane`, `PlaneWire`, `PlaneSolid`
- `Circle`, `Arc`, `ArcBetween`, `Disk`
- `Sphere`, `Hemisphere`, `CappedHemisphere`
- `Cylinder`, `CappedCylinder`, `Capsule`, `CapsuleHemi`
- `Cone`, `Tube`, `Torus`, `Helix`
- `Pyramid`, `Tetrahedron`, `Prism`
- `Frustum` / `SimpleFrustum`

### Arrows and vectors
- `Arrow`, `DoubleArrow`, `ThickArrow`, `DoubleThickArrow`
- `VelocityArrow`, `AccelerationArrow`, `VelocityAccelerationArrows`
- `Basis` (coordinate axes)

### Text
- `Text()` — in the world
- `ScreenText()` — on screen
- `EntityText()` / `EntityTextAtPos()`
- Support for `TextFloat`, `TextInt`, `TextVec`

### Additional Features
- Support for solid (filled shapes) and wireframe modes
- Convenient colors in `DebugRendererColors`
- Extensible

### Technical Info
- The utility calls functions from VScript because VScript supports native rendering.
- All computations are performed on the Angel Script side.

## Installation and Use

1. Copy `DebugRenderer.as` in 'p2ce/code/'.
2. Include it in your script:

```as
#include "DebugRenderer.as"

class CMyEntity : CBaseEntity
{
    DebugRenderer@ m_dbg;

    void Spawn()
    {
        @m_dbg = DebugRenderer(self);
        m_dbg.Init();
    }

    void Think()
    {
        if (m_dbg.IsValid())
        {
            Vector pos = self.GetOrigin();
            m_dbg.Arrow(pos, pos + Vector(0, 100, 50), DebugRendererColors::RED);
            m_dbg.Sphere(pos + Vector(0, 0, 80), 25.0, DebugRendererColors::CYAN, 80);
            
            m_dbg.Text(pos + Vector(0, 0, 120), "Hello Debug!");
        }
    }
}
```

# Licence
You are free to use, modify and share this library under the terms of the MIT License. The only condition is keeping the copyright notice, and stating whether or not the code was modified. 
See LICENSE for details.

