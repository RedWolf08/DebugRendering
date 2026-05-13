// DebugRenderer.as

/*
    MIT License

    Copyright (c) 2026 Ermek

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    SPDX-License-Identifier: MIT
*/


namespace DebugRendererColors
{
    const Color RED     = Color(255, 50, 50);
    const Color GREEN   = Color(80, 200, 80);
    const Color BLUE    = Color(50, 100, 255);

    const Color YELLOW  = Color(255, 220, 0);
    const Color CYAN    = Color(0, 220, 220);
    const Color MAGENTA = Color(220, 0, 220);

    const Color WHITE   = Color(255, 255, 255);
    const Color ORANGE  = Color(255, 140, 0);
    const Color GRAY    = Color(140, 140, 140);

    const Color AXIS_X  = Color(255, 50, 50);
    const Color AXIS_Y  = Color(80, 200, 80);
    const Color AXIS_Z  = Color(50, 100, 255);
}

const float DEG2RAD = 0.017453292519943295f;
const float RAD2DEG = 1.0f / DEG2RAD;

class DebugRenderer
{
    private CBaseEntity@ m_logic = null;
    private CBaseEntity@ m_owner = null;
    private Variant m_variant;


    
    // ----------------------------------------------
    //  Init/Destroy
    // ----------------------------------------------

    DebugRenderer(CBaseEntity@ owner)
    {
        @m_owner = owner;
        m_variant.SetString("");
    }

    bool Init()
    {
        @m_logic = util::CreateEntityByName("logic_script");
        if (m_logic is null)
        {
            Warning("DebugRenderer: failed to create logic_script\n");
            return false;
        }

        m_logic.KeyValue("targetname", "_dbgr_" + m_owner.GetEntityIndex());
        m_logic.Spawn();
        return true;
    }

    void Destroy()
    {
        if (m_logic !is null)
        {
            m_logic.Remove();
            @m_logic = null;
        }
    }

    bool IsValid() const { return m_logic !is null; }

    // Manual winding override. Only affects Triangle() calls outside of _BatchBegin/_BatchFlush.
    // For internal geometry, use TriangleInv() directly.
    // To be honest, I'm really too lazy to add the `invert` parameter to every method.
    private bool m_invertTriangles = false;
    bool INVERT_TRIANGLES
    {
        get const
        {
            return m_invertTriangles;
        }
        
        set
        {
            m_invertTriangles = value;
        }
    }


    // ==============================================
    //
    // 
    //
    // ==============================================




    // ==============================================
    //
    //  Primitives — overloads with presets
    //
    // ==============================================


    void Line(const Vector&in a, const Vector&in b,
              int r, int g, int bv, float dur = 0.05f)
    {
        _exec("DebugDrawLine(" +
              _v(a) + "," + _v(b) + "," +
              r + "," + g + "," + bv + ",false," + dur + ")");
    }

    void Line(const Vector&in a, const Vector&in b,
              const Color&in color, float dur = 0.05f)
    {
        Line(a, b, color[0], color[1], color[2], dur);
    }


    void Circle(const Vector&in origin, const Vector&in normal, float radius,
          int r, int g, int b, float dur = 0.05f, float segments = 16)
    {
        if (radius <= 0.001f || segments < 3) return;

        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right = normal.Cross(arb).Normalized();
        Vector up    = normal.Cross(right).Normalized();

        float step = 6.283185f / segments;

        _BatchBegin();

        for (int i = 0; i < segments; i++)
        {
            float a1 = float(i)     * step;
            float a2 = float(i + 1) * step;

            Vector p1 = right * cos(a1) * radius + up * sin(a1) * radius;
            Vector p2 = right * cos(a2) * radius + up * sin(a2) * radius;

            Vector v1 = origin + p1;
            Vector v2 = origin + p2;

            // Wireframe
            _bLine(v1, v2, r, g, b, dur); 
        }

        _BatchFlush();
    }

    void Circle(const Vector&in origin, const Vector&in normal, float radius,
            const Color&in color, int alpha = 255, float dur = 0.05f, float segments = 16)
    {
        Circle(origin, normal, radius, color[0], color[1], color[2], dur, segments);
    }


    // ----------------------------------------------
    //  Arc
    // ----------------------------------------------
    void Arc(const Vector&in center, 
            const Vector&in normal, 
            const Vector&in startDir, 
            float radius,
            float angleDegrees,       
            int r, int g, int b, 
            int alpha = 0,               
            float dur = 0.05f, 
            float segments = 24)
    {
        if (radius <= 0.001f || angleDegrees <= 0.001f) return;

        Vector n = normal.Normalized();
        Vector dir = startDir.Normalized();

        Vector right = n.Cross(dir).Normalized();
        Vector up    = dir;                    

        float step = (angleDegrees * DEG2RAD) / segments;
        float currentAngle = 0.0f;

        Vector prev = center + up * radius;

        _BatchBegin();

        for (int i = 1; i <= segments; i++)
        {
            currentAngle = float(i) * step;
            
            float ca = cos(currentAngle);
            float sa = sin(currentAngle);

            Vector current = center + (right * sa + up * ca) * radius;

            if (alpha <= 0)
            {
                _bLine(prev, current, r, g, b, dur);
            }
            else
            {
                Triangle(center, prev, current, r, g, b, alpha, dur);
            }

            prev = current;
        }

        _BatchFlush();
    }

    void Arc(const Vector&in center, 
            const Vector&in normal, 
            const Vector&in startDir, 
            float radius,
            float angleDegrees,
            const Color&in color, 
            int alpha = 0, 
            float dur = 0.05f, 
            float segments = 24)
    {
        Arc(center, normal, startDir, radius, angleDegrees, 
            color[0], color[1], color[2], alpha, dur, segments);
    }


    void ArcBetween(const Vector&in center, const Vector&in normal,
                const Vector&in startDir, const Vector&in endDir,
                float radius, int r, int g, int bv, int alpha = 0,
                float dur = 0.05f, float segments = 24)
    {
        Vector a = startDir.Normalized();
        Vector b = endDir.Normalized();
        
        float angle = acos(a.Dot(b)) * RAD2DEG;
        if (angle < 0.1f) angle = 0.1f;
        
        Arc(center, normal, a, radius, angle, r, g, bv, alpha, dur, segments);
    }

    void ArcBetween(const Vector&in center, const Vector&in normal,
                const Vector&in startDir, const Vector&in endDir,
                float radius, const Color&in color, int alpha = 0,
                float dur = 0.05f, float segments = 24)
    {
        ArcBetween(center, normal, startDir, endDir, radius, 
            color[0], color[1], color[2], alpha, dur, segments);
    }


    void _bTri(const Vector&in p1, const Vector&in p2, const Vector&in p3,
           int r, int g, int b, int a, float dur)
    {
        m_batch += "DebugDrawTri(" +
                _v(p1) + "," + _v(p2) + "," + _v(p3) + "," +
                r + "," + g + "," + b + "," + a + ",false," + dur + ");";
    }

    void _bTri(const Vector&in p1, const Vector&in p2, const Vector&in p3,
           const Color&in color, int a, float dur)
    {
        _bTri(p1, p2, p3, color[0], color[1], color[2], a, dur);
    }

    
    void _bTriInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                int r, int g, int b, int a, float dur)
    {
        _bTri(p1, p3, p2, r, g, b, a, dur);
    }

    void _bTriInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                const Color&in color, int a, float dur)
    {
        _bTri(p1, p3, p2, color[0], color[1], color[2], a, dur);
    }


    void Triangle(const Vector&in p1, const Vector&in p2, const Vector&in p3,
              int r, int g, int b, int a = 255, float dur = 0.05f)
    {
        if (a <= 0)
        {
            _bLine(p1, p2, r, g, b, dur);
            _bLine(p2, p3, r, g, b, dur);
            _bLine(p3, p1, r, g, b, dur);
        }
        else
        {
            if (m_batch.length() > 0)
            {
                _bTri(p1, p2, p3, r, g, b, a, dur);
            }
            else
            {
                if (INVERT_TRIANGLES)
                {
                    _exec("DebugDrawTri(" + _v(p1) + "," + _v(p3) + "," + _v(p2) + "," +
                        r + "," + g + "," + b + "," + a + ",false," + dur + ")");
                }
                else
                {
                    _exec("DebugDrawTri(" + _v(p1) + "," + _v(p2) + "," + _v(p3) + "," +
                        r + "," + g + "," + b + "," + a + ",false," + dur + ")");
                }
            }
        }
    }

    void Triangle(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                const Color&in color, int a = 255, float dur = 0.05f)
    {
        Triangle(p1, p2, p3, color[0], color[1], color[2], a, dur);
    }


    void TriangleInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                 int r, int g, int b, int a = 255, float dur = 0.05f)
    {
        Triangle(p1, p3, p2, r, g, b, a, dur); 
    }

    void TriangleInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                 const Color&in color, int a = 255, float dur = 0.05f)
    {
        Triangle(p1, p3, p2, color[0], color[1], color[2], a, dur);
    }


    void Box(const Vector&in origin,
             const Vector&in mins, const Vector&in maxs,
             int r, int g, int bv, int alpha = 0, float dur = 0.05f)
    {
        _exec("DebugDrawBox(" +
              _v(origin) + "," + _v(mins) + "," + _v(maxs) + "," +
              r + "," + g + "," + bv + "," + alpha + "," + dur + ")");
    }

    void Box(const Vector&in origin,
             const Vector&in mins, const Vector&in maxs,
             const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Box(origin, mins, maxs, color[0], color[1], color[2], alpha, dur);
    }


    void BoxAngles(const Vector&in origin,
               const Vector&in mins, const Vector&in maxs,
               const QAngle&in angles,
               int r, int g, int bv, int alpha = 0, float dur = 0.05f)
    {
        _exec("DebugDrawBoxAngles(" +
            _v(origin) + "," + _v(mins) + "," + _v(maxs) + "," +
            _v(angles) + "," +                    
            r + "," + g + "," + bv + "," + alpha + "," + dur + ")");
    }

    void BoxAngles(const Vector&in origin,
                const Vector&in mins, const Vector&in maxs,
                const QAngle&in angles,
                const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        BoxAngles(origin, mins, maxs, angles, color[0], color[1], color[2], alpha, dur);
    }


    void OBox(const Vector&in center, const Vector&in size, const QAngle&in angles, 
          int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Vector mins = size * -0.5f;
        Vector maxs = size * 0.5f;
        BoxAngles(center, mins, maxs, angles, r, g, b, alpha, dur);
    }

    void OBox(const Vector&in center, const Vector&in size, const QAngle&in angles, 
          const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        OBox(center, size, angles, color[0], color[1], color[2], alpha, dur);
    }


    // Useful? Maybe not, buuut okay
    void Grid(const Vector&in origin)
    {
        _exec("DebugDrawGrid(" + _v(origin) + ")");
    }


    void Cross(const Vector&in pos, float size,
            int r, int g, int b, float dur = 0.05f)
    {
        
        _BatchBegin();

        // X axis
        _bLine(pos - Vector(size, 0, 0), 
            pos + Vector(size, 0, 0), 
            r, g, b, dur);

        // Y axis
        _bLine(pos - Vector(0, size, 0), 
            pos + Vector(0, size, 0), 
            r, g, b, dur);

        // Z axis
        _bLine(pos - Vector(0, 0, size), 
            pos + Vector(0, 0, size), 
            r, g, b, dur);

        _BatchFlush();
    }
    
    void Cross(const Vector&in pos, float size,
               const Color&in color, float dur = 0.05f)
    {
        Cross(pos, size, color[0], color[1], color[2], dur);
    }


    void PlaneSolid(const Vector&in origin, const Vector&in normal, 
                float size = 100.0f,
                int r = 255, int g = 100, int b = 100, int a = 80, 
                float dur = 0.05f)
    {
        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);
        
        Vector right = normal.Cross(arb).Normalized() * (size * 0.5f);
        Vector up    = normal.Cross(right).Normalized() * (size * 0.5f);
        
        Vector p1 = origin + right + up;
        Vector p2 = origin + right - up;
        Vector p3 = origin - right - up;
        Vector p4 = origin - right + up;

        _BatchBegin();
        
        Triangle(p1, p2, p3, r, g, b, a, dur);
        Triangle(p1, p3, p4, r, g, b, a, dur);
        
        _BatchFlush();
    }

    void PlaneWire(const Vector&in origin, const Vector&in normal, 
               float size = 100.0f, int divisions = 4,
               int r = 255, int g = 255, int b = 100, 
               float dur = 0.05f)
    {
        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);
        
        Vector right = normal.Cross(arb).Normalized() * (size * 0.5f);
        Vector up    = normal.Cross(right).Normalized() * (size * 0.5f);

        _BatchBegin();

        Line(origin + right + up, origin + right - up, r, g, b, dur);
        Line(origin + right - up, origin - right - up, r, g, b, dur);
        Line(origin - right - up, origin - right + up, r, g, b, dur);
        Line(origin - right + up, origin + right + up, r, g, b, dur);

        if (divisions > 1)
        {
            float step = 1.0f / divisions;
            for (int i = 1; i < divisions; i++)
            {
                float t = step * i - 0.5f;
                
                // Horizontal lines
                Line(origin + right + up + (up * -2.0f * t), 
                    origin - right + up + (up * -2.0f * t), r, g, b, dur);
                
                // Vertical lines
                Line(origin + right + up + (right * -2.0f * t), 
                    origin + right - up + (right * -2.0f * t), r, g, b, dur);
            }
        }

        _BatchFlush();
    }

    void Plane(const Vector&in origin, const Vector&in normal, float size = 100.0f,
           int r = 255, int g = 100, int b = 100, int a = 255, float dur = 0.05f)
    {
        PlaneWire(origin, normal, size, 4, r, g, b, dur);
        PlaneSolid(origin, normal, size, r, g, b, a, dur);
    }


    void Disk(const Vector&in origin, const Vector&in normal, float radius,
          int r, int g, int b, int alpha = 255, bool circle = false, float dur = 0.05f, float segments = 16)
    {
        if (radius <= 0.001f || segments < 3) return;

        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right = normal.Cross(arb).Normalized();
        Vector up    = normal.Cross(right).Normalized();

        float step = 6.283185f / segments;

        _BatchBegin();

        for (int i = 0; i < segments; i++)
        {
            float a1 = float(i)     * step;
            float a2 = float(i + 1) * step;

            Vector p1 = right * cos(a1) * radius + up * sin(a1) * radius;
            Vector p2 = right * cos(a2) * radius + up * sin(a2) * radius;

            Vector v1 = origin + p1;
            Vector v2 = origin + p2;

            if(circle)
            {
                _bLine(v1, v2, r, g, b, dur); 
            }

            if (alpha <= 0)
            {
                // Wireframe
                _bLine(origin, v1, r, g, b, dur);
                _bLine(origin, v2, r, g, b, dur);
            }
            else
            {
                // Solid
                TriangleInv(origin, v1, v2, r, g, b, alpha, dur);
                
            }
        }

        _BatchFlush();
    }

    void Disk(const Vector&in origin, const Vector&in normal, float radius,
            const Color&in color, int alpha = 255, bool circle = false, float dur = 0.05f, float segments = 16)
    {
        Disk(origin, normal, radius, color[0], color[1], color[2], alpha, circle, dur, segments);
    }




    // ==============================================
    //
    //  ARROWS
    //
    // ==============================================


    // ----------------------------------------------
    //  Arrow Head (helper for Arrow and DoubleArrow)
    // ----------------------------------------------

    private void _ArrowHeadCone(const Vector&in tip, const Vector&in dir,
                            float headLength, float headWidth,
                            int r, int g, int b, int alpha = 0, float dur = 0.05f,
                            float segments = 12)
    {
        if (headLength <= 0.0f) return;

        Vector baseCenter = tip - dir * headLength;
        
        float halfAngleDeg = RAD2DEG * atan(headWidth / headLength);
        
        Cone(tip, dir * -1.0f, headLength, halfAngleDeg, r, g, b, alpha, dur, segments);
        
        if (alpha > 0)
        {
            Disk(baseCenter, -dir, headWidth, r, g, b, alpha, false, dur, segments);
        }
        else
        {
            Disk(baseCenter, -dir, headWidth, r, g, b, 0, false, dur, segments);
        }
    }


    // ----------------------------------------------
    //  New Arrow
    // ------------------------------

    void Arrow(const Vector&in from, const Vector&in to,
               int r, int g, int bv, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Line(from, to, r, g, bv, dur);
        Vector dir = (to - from).Normalized();
        _ArrowHeadCone(to, dir, headSize, headSize * 0.6f, r, g, bv, 0, dur, segments);
    }

    void Arrow(const Vector&in from, const Vector&in to,
               const Color&in color, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Arrow(from, to, color[0], color[1], color[2], dur, headSize, segments);
    }

    void DoubleArrow(const Vector&in from, const Vector&in to,
                     int r, int g, int bv, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Line(from, to, r, g, bv, dur);
        
        Vector dir = (to - from).Normalized();
        _ArrowHeadCone(to, dir, headSize, headSize * 0.6f, r, g, bv, 0, dur, segments);
        _ArrowHeadCone(from, -dir, headSize, headSize * 0.6f, r, g, bv, 0, dur, segments);
    }

    void DoubleArrow(const Vector&in from, const Vector&in to,
                     const Color&in color, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        DoubleArrow(from, to, color[0], color[1], color[2], dur, headSize, segments);
    }


    // ------------------------------
    //  Old Arrow
    // ------------------------------
    
    void ArrowOld(const Vector&in from, const Vector&in to,
               int r, int g, int bv, float dur = 0.05f)
    {
        Line(from, to, r, g, bv, dur);
        Cross(to, 3.0f, r, g, bv, dur);
    }

    void ArrowOld(const Vector&in from, const Vector&in to,
               const Color&in color, float dur = 0.05f)
    {
        ArrowOld(from, to, color[0], color[1], color[2], dur);
    }
    
    void DoubleArrowOld(const Vector&in from, const Vector&in to,
                     int r, int g, int bv, float dur = 0.05f)
    {
        Line(from, to, r, g, bv, dur);
        Cross(from, 3.5f, r, g, bv, dur);
        Cross(to,   3.5f, r, g, bv, dur);
    }

    void DoubleArrowOld(const Vector&in from, const Vector&in to,
                     const Color&in color, float dur = 0.05f)
    {
        DoubleArrowOld(from, to, color[0], color[1], color[2], dur);
    }



    // ==============================================
    //
    //  CYLINDER
    //
    // ==============================================
    

    void Cylinder(const Vector&in start, const Vector&in end, float radius,
                  int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Vector dir = end - start;
        float len = dir.Length();
        if (len < 0.001f) return;
        dir /= len;
        
        // Perpendicular vectors
        Vector arb = Vector(0, 0, 1);
        if (fabs(dir.z) > 0.98f)
            arb = Vector(1, 0, 0);
        
        Vector right = dir.Cross(arb).Normalized();
        Vector up    = dir.Cross(right);
        
        float step = 6.283185f / segments;
        
        _BatchBegin();
        
        Vector prevS, prevE;
        bool hasPrev = false;
        
        for (int i = 0; i <= segments; i++)
        {
            float angle = float(i) * step;
            float ca = cos(angle), sa = sin(angle);
            
            Vector offset = right * (ca * radius) + up * (sa * radius);
            
            Vector s = start + offset;
            Vector e = end   + offset;
            
            if (hasPrev)
            {
                if (alpha <= 0)
                {
                    _bLine(prevS, s, r, g, b, dur);   // start circle
                    _bLine(prevE, e, r, g, b, dur);   // end circle
                    _bLine(s, e, r, g, b, dur);       // side
                }
                else
                {
                    TriangleInv(prevS, s, e,   r, g, b, alpha, dur);
                    TriangleInv(prevS, e, prevE, r, g, b, alpha, dur);
                }
            }
            
            prevS = s;
            prevE = e;
            hasPrev = true;
        }
        
        _BatchFlush();
    }

    void Cylinder(const Vector&in start, const Vector&in end, float radius,
                  const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Cylinder(start, end, radius, color[0], color[1], color[2], alpha, dur, segments);
    }


    // ------------------------------
    //  Capped Cylinder (a cylinder with discs at each end)
    // ------------------------------

    void CappedCylinder(const Vector&in start, const Vector&in end, float radius,
                    int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {

        Cylinder(start, end, radius, r, g, b, alpha, dur, segments);
        
        if (alpha <= 0)
        {
            Vector dir = (end - start).Normalized();
            Disk(start, -dir, radius, r, g, b, 0, false, dur, segments);
            Disk(end,    dir, radius, r, g, b, 0, false, dur, segments);            
        }
        else
        {
            Vector dir = (end - start).Normalized();
            Disk(start, -dir, radius, r, g, b, alpha, false, dur, segments);
            Disk(end,    dir, radius, r, g, b, alpha, false, dur, segments);
        }
        
    }

    void CappedCylinder(const Vector&in start, const Vector&in end, float radius,
                        const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        CappedCylinder(start, end, radius, color[0], color[1], color[2], alpha, dur, segments);
    }



    // ==============================================
    //
    //  SPHERE / HEMISPHERE
    //
    // ==============================================


    void Sphere(const Vector&in center, float radius,
                int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 24)
    {
        if (segments < 8)  segments = 8;
        if (segments > 64) segments = 64;

        _BatchBegin();

        float latStep = 3.14159265359f / segments;
        float lonStep = 6.28318530718f / segments;

        for (int lat = 0; lat < segments; lat++)
        {
            float theta1 = float(lat)     * latStep;
            float theta2 = float(lat + 1) * latStep;

            float sinT1 = sin(theta1), cosT1 = cos(theta1);
            float sinT2 = sin(theta2), cosT2 = cos(theta2);

            for (int lon = 0; lon < segments; lon++)
            {
                float phi1 = float(lon)     * lonStep;
                float phi2 = float(lon + 1) * lonStep;

                float sinP1 = sin(phi1), cosP1 = cos(phi1);
                float sinP2 = sin(phi2), cosP2 = cos(phi2);

                Vector p1 = center + Vector(sinT1 * cosP1, sinT1 * sinP1, cosT1) * radius;
                Vector p2 = center + Vector(sinT1 * cosP2, sinT1 * sinP2, cosT1) * radius;
                Vector p3 = center + Vector(sinT2 * cosP2, sinT2 * sinP2, cosT2) * radius;
                Vector p4 = center + Vector(sinT2 * cosP1, sinT2 * sinP1, cosT2) * radius;

                if (alpha <= 0)
                {
                    _bLine(p1, p2, r, g, b, dur);
                    _bLine(p2, p3, r, g, b, dur);
                }
                else
                {
                    Triangle(p1, p2, p3, r, g, b, alpha, dur);
                    Triangle(p1, p3, p4, r, g, b, alpha, dur);
                }
            }
        }

        _BatchFlush();
    }

    void Sphere(const Vector&in center, float radius, const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Sphere(center, radius, color[0], color[1], color[2], alpha, dur, segments);
    }


    void Hemisphere(const Vector&in center, const Vector&in upDir, float radius,
                    int r, int g, int b, int alpha = 0,
                    float dur = 0.05f, float segments = 16, float rings = 8)
    {
        Vector forward, right;
        VectorVectors(upDir.Normalized(), right, forward);

        float ringStep = 1.0f / rings;
        float angleStep = 6.283185f / segments;

        _BatchBegin();

        for (int ring = 0; ring < rings; ring++)
        {
            float t1 = float(ring) * ringStep;
            float t2 = float(ring + 1) * ringStep;

            float phi1 = asin(t1);
            float phi2 = asin(t2);

            float r1 = radius * cos(phi1);
            float r2 = radius * cos(phi2);

            float h1 = radius * sin(phi1);
            float h2 = radius * sin(phi2);

            Vector c1 = center + upDir * h1;
            Vector c2 = center + upDir * h2;

            for (int i = 0; i < segments; i++)
            {
                float a1 = float(i) * angleStep;
                float a2 = float(i + 1) * angleStep;

                Vector p1 = c1 + right * (cos(a1)*r1) + forward * (sin(a1)*r1);
                Vector p2 = c1 + right * (cos(a2)*r1) + forward * (sin(a2)*r1);
                Vector p3 = c2 + right * (cos(a2)*r2) + forward * (sin(a2)*r2);
                Vector p4 = c2 + right * (cos(a1)*r2) + forward * (sin(a1)*r2);

                if (alpha <= 0)
                {
                    _bLine(p1, p2, r,g,b,dur);
                    _bLine(p2, p3, r,g,b,dur);
                }
                else
                {
                    Triangle(p1, p2, p3, r,g,b,alpha,dur);
                    Triangle(p1, p3, p4, r,g,b,alpha,dur);
                }
            }
        }

        _BatchFlush();
    }

    void Hemisphere(const Vector&in center, const Vector&in upDir, float radius,
                    const Color&in color, int alpha = 0,
                    float dur = 0.05f, float segments = 16, float rings = 8)
    {
        Hemisphere(center, upDir, radius, color[0], color[1], color[2], alpha, dur, segments, rings);
    }


    // ------------------------------
    //  Capped Hemisphere (hemisphere + disk)
    // -------------------------------------

    void CappedHemisphere(const Vector&in center, const Vector&in upDir, float radius,
                        int r, int g, int b, int alpha = 0,
                        float dur = 0.05f, float segments = 16, float rings = 8)
    {
        Vector dir = upDir.Normalized();

        Hemisphere(center, dir, radius, r, g, b, alpha, dur, segments, rings);

        Vector baseCenter = center;  

        if (alpha <= 0)
        {
            Disk(baseCenter, -dir, radius, r, g, b, 0, false, dur, segments);
        }
        else
        {
            Disk(baseCenter, -dir, radius, r, g, b, alpha, false, dur, segments);
        }
    }

    void CappedHemisphere(const Vector&in center, const Vector&in upDir, float radius,
                        const Color&in color, int alpha = 0,
                        float dur = 0.05f, float segments = 16, float rings = 8)
    {
        CappedHemisphere(center, upDir, radius, color[0], color[1], color[2], alpha, dur, segments, rings);
    }
        
    


    // ==============================================
    //
    //  CAPSULE
    //
    // ==============================================


    // -------------------------------------
    //  Capsule (cylinder + spheres)
    // --------------------------------------------
    
    void Capsule(const Vector&in start, const Vector&in end, float radius,
                 int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Cylinder(start, end, radius, r, g, b, alpha, dur, segments);

        Sphere(start, radius, r, g, b, alpha, dur, segments);
        Sphere(end,   radius, r, g, b, alpha, dur, segments);
    }

    void Capsule(const Vector&in start, const Vector&in end, float radius,
                 const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Capsule(start, end, radius, color[0], color[1], color[2], alpha, dur, segments);
    }


    // --------------------------------------------
    //  Capsule with different radii (trapezoidal)
    // ----------------------------------------------

    void Capsule(const Vector&in start, const Vector&in end,
                 float radiusStart, float radiusEnd,
                 int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Vector dir = end - start;
        float len = dir.Length();
        if (len < 0.001f) return;
        dir /= len;

        Vector arb = Vector(0,0,1);
        if (fabs(dir.z) > 0.98f) arb = Vector(1,0,0);

        Vector right = dir.Cross(arb).Normalized();
        Vector up    = dir.Cross(right);

        float step = 6.283185f / segments;

        _BatchBegin();

        Vector prevS, prevE;
        bool hasPrev = false;

        for (int i = 0; i <= segments; i++)
        {
            float a  = float(i) * step;
            float ca = cos(a), sa = sin(a);

            Vector offsetS = right * (ca * radiusStart) + up * (sa * radiusStart);
            Vector offsetE = right * (ca * radiusEnd)   + up * (sa * radiusEnd);

            Vector s = start + offsetS;
            Vector e = end   + offsetE;

            if (hasPrev)
            {
                if (alpha <= 0)
                {
                    _bLine(prevS, s, r, g, b, dur);
                    _bLine(prevE, e, r, g, b, dur);
                }
                else
                {
                    Triangle(prevS, s, e, r, g, b, alpha, dur);
                    Triangle(prevS, e, prevE, r, g, b, alpha, dur);
                }
            }
            _bLine(s, e, r, g, b, dur);  

            prevS = s;
            prevE = e;
            hasPrev = true;
        }

        Sphere(start, radiusStart, r, g, b, alpha, dur, segments);
        Sphere(end,   radiusEnd,   r, g, b, alpha, dur, segments);

        _BatchFlush();
    }

    void Capsule(const Vector&in start, const Vector&in end,
                 float radiusStart, float radiusEnd,
                 const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Capsule(start, end, radiusStart, radiusEnd,
                color[0], color[1], color[2], alpha, dur, segments);
    }




    // ==============================================
    //
    //  CapsuleHemi
    //
    // ==============================================


    void CapsuleHemi(const Vector&in start, const Vector&in end, float radius,
                     int r, int g, int b, int alpha = 0, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        if ((end - start).LengthSqr() < 0.0001f)
        {
            Sphere(start, radius, r, g, b, alpha, dur, segments);
            return;
        }


        Cylinder(start, end, radius, r, g, b, alpha, dur, segments);


        Vector dir = (end - start).Normalized();

        Hemisphere(start, -dir, radius, r, g, b, alpha, dur, segments, rings);
        Hemisphere(end,   dir,  radius, r, g, b, alpha, dur, segments, rings);
    }

    void CapsuleHemi(const Vector&in start, const Vector&in end, float radius,
                     const Color&in color, int alpha = 0, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        CapsuleHemi(start, end, radius, color[0], color[1], color[2], alpha, dur, segments, rings);
    }


    // ----------------------------------------------
    //  CapsuleHemi with different radii
    // ----------------------------------------------

    void CapsuleHemi(const Vector&in start, const Vector&in end,
                     float radiusStart, float radiusEnd,
                     int r, int g, int b, int alpha = 0, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        Vector dir = end - start;
        float len = dir.Length();
        if (len < 0.001f)
        {
            Sphere(start, radiusStart, r, g, b, alpha, dur, segments);
            return;
        }
        dir /= len;

        Capsule(start, end, radiusStart, radiusEnd, r, g, b, alpha, dur, segments);

        Hemisphere(start, -dir, radiusStart, r, g, b, alpha, dur, segments, rings);
        Hemisphere(end,   dir,  radiusEnd,   r, g, b, alpha, dur, segments, rings);
    }

    void CapsuleHemi(const Vector&in start, const Vector&in end,
                     float radiusStart, float radiusEnd,
                     const Color&in color, int alpha = 0, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        CapsuleHemi(start, end, radiusStart, radiusEnd,
                    color[0], color[1], color[2], alpha, dur, segments, rings);
    }




    // ==============================================
    //
    //  FRUSTUM
    //
    // ==============================================


    void SimpleFrustum(const Vector&in ntl, const Vector&in ntr,
                       const Vector&in nbl, const Vector&in nbr,
                       const Vector&in ftl, const Vector&in ftr,
                       const Vector&in fbl, const Vector&in fbr,
                       int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        _BatchBegin();

        // Near plane
        if (alpha <= 0)
        {
            _bLine(ntl, ntr, r, g, b, dur);
            _bLine(ntr, nbr, r, g, b, dur);
            _bLine(nbr, nbl, r, g, b, dur);
            _bLine(nbl, ntl, r, g, b, dur);
        }
        else
        {
            Triangle(ntl, ntr, nbr, r, g, b, alpha, dur);
            Triangle(ntl, nbr, nbl, r, g, b, alpha, dur);
        }

        // Far plane
        if (alpha <= 0)
        {
            _bLine(ftl, ftr, r, g, b, dur);
            _bLine(ftr, fbr, r, g, b, dur);
            _bLine(fbr, fbl, r, g, b, dur);
            _bLine(fbl, ftl, r, g, b, dur);
        }
        else
        {
            TriangleInv(ftl, ftr, fbr, r, g, b, alpha, dur);
            TriangleInv(ftl, fbr, fbl, r, g, b, alpha, dur);
        }

        // Side faces
        if (alpha <= 0)
        {
            _bLine(ntl, ftl, r, g, b, dur);
            _bLine(ntr, ftr, r, g, b, dur);
            _bLine(nbl, fbl, r, g, b, dur);
            _bLine(nbr, fbr, r, g, b, dur);
        }
        else
        {
            // Right
            TriangleInv(ntr, nbr, fbr, r, g, b, alpha, dur);
            TriangleInv(ntr, fbr, ftr, r, g, b, alpha, dur);
            // Left
            Triangle(ntl, nbl, fbl, r, g, b, alpha, dur);
            Triangle(ntl, fbl, ftl, r, g, b, alpha, dur);
            // Top
            TriangleInv(ntl, ntr, ftr, r, g, b, alpha, dur);
            TriangleInv(ntl, ftr, ftl, r, g, b, alpha, dur);
            // Bottom
            Triangle(nbl, nbr, fbr, r, g, b, alpha, dur);
            Triangle(nbl, fbr, fbl, r, g, b, alpha, dur);
        }

        _BatchFlush();
    }

    void SimpleFrustum(const Vector&in ntl, const Vector&in ntr,
                       const Vector&in nbl, const Vector&in nbr,
                       const Vector&in ftl, const Vector&in ftr,
                       const Vector&in fbl, const Vector&in fbr,
                       const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        SimpleFrustum(ntl, ntr, nbl, nbr, ftl, ftr, fbl, fbr,
                      color[0], color[1], color[2], alpha, dur);
    }


    void Frustum(const Vector&in origin,
                 const QAngle&in angles,
                 float fov,                    
                 float aspectRatio,            
                 float nearDist,
                 float farDist,
                 const Vector&in farOffset,    
                 int r, int g, int b, int alpha = 0,
                 float dur = 0.05f)
    {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);

        float tanHalfFOV = tan(fov * 0.5f * DEG2RAD);

        // Near plane
        Vector nearCenter = origin + forward * nearDist;
        float nearHeight = tanHalfFOV * nearDist;
        float nearWidth  = nearHeight * aspectRatio;

        Vector ntl = nearCenter + up * nearHeight - right * nearWidth;
        Vector ntr = nearCenter + up * nearHeight + right * nearWidth;
        Vector nbl = nearCenter - up * nearHeight - right * nearWidth;
        Vector nbr = nearCenter - up * nearHeight + right * nearWidth;

        // Far plane
        Vector farCenter = origin + forward * farDist + farOffset;
        float farHeight = tanHalfFOV * farDist;
        float farWidth  = farHeight * aspectRatio;

        Vector ftl = farCenter + up * farHeight - right * farWidth;
        Vector ftr = farCenter + up * farHeight + right * farWidth;
        Vector fbl = farCenter - up * farHeight - right * farWidth;
        Vector fbr = farCenter - up * farHeight + right * farWidth;

        SimpleFrustum(ntl, ntr, nbl, nbr, ftl, ftr, fbl, fbr, r, g, b, alpha, dur);
    }

    void Frustum(const Vector&in origin,
                 const QAngle&in angles,
                 float fov,
                 float aspectRatio,
                 float nearDist,
                 float farDist,
                 const Vector&in farOffset,
                 const Color&in color, int alpha = 0,
                 float dur = 0.05f)
    {
        Frustum(origin, angles, fov, aspectRatio, nearDist, farDist, farOffset,
                color[0], color[1], color[2], alpha, dur);
    }

    void Frustum(const Vector&in origin, const QAngle&in angles,
                 float fov = 90.0f, float aspectRatio = 16.0f/9.0f,
                 float nearDist = 10.0f, float farDist = 1000.0f,
                 int r = 100, int g = 180, int b = 255, int alpha = 0, float dur = 0.05f)
    {
        Frustum(origin, angles, fov, aspectRatio, nearDist, farDist, Vector(0,0,0), r, g, b, alpha, dur);
    }




    // ==============================================
    //
    //  CONE
    //
    // ==============================================


    void Cone(const Vector&in apex, const Vector&in dir, float length, float halfAngleDeg,
              int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Vector right, up;
        Vector arb = Vector(0,0,1);
        if (fabs(dir.z) > 0.98f) arb = Vector(1,0,0);
        right = dir.Cross(arb).Normalized();
        up = dir.Cross(right);

        float radius = tan(halfAngleDeg * DEG2RAD) * length;
        float step = 6.283185f / segments;

        _BatchBegin();

        Vector prev;
        for (int i = 0; i <= segments; i++)
        {
            float a = float(i) * step;
            Vector p = apex + dir * length + right * (cos(a) * radius) + up * (sin(a) * radius);

            if (alpha <= 0)
            {
                if (i > 0) _bLine(prev, p, r,g,b,dur);
                _bLine(apex, p, r,g,b,dur);
            }
            else
            {
                if (i > 0) Triangle(apex, prev, p, r,g,b,alpha,dur);
            }
            prev = p;
        }

        _BatchFlush();
    }

    void Cone(const Vector&in eyePos, const Vector&in fwd, const Vector&in right, const Vector&in up,
              float near, float far, float halfAngleDeg,
              int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        // Frustum-style cone
        float rNear = tan(halfAngleDeg * DEG2RAD) * near;
        float rFar  = tan(halfAngleDeg * DEG2RAD) * far;
        float step = 6.283185f / segments;

        _BatchBegin();
        Vector prevN, prevF;
        bool hasPrev = false;

        for (int i = 0; i <= segments; i++)
        {
            float a = float(i) * step;
            float ca = cos(a), sa = sin(a);

            Vector cn = eyePos + fwd * near + right*(ca*rNear) + up*(sa*rNear);
            Vector cf = eyePos + fwd * far  + right*(ca*rFar)  + up*(sa*rFar);

            if (hasPrev)
            {
                if (alpha <= 0)
                {
                    _bLine(prevN, cn, r,g,b,dur);
                    _bLine(prevF, cf, r,g,b,dur);
                    _bLine(cn, cf, r,g,b,dur);
                }
                else
                {
                    Triangle(prevN, cn, cf, r,g,b,alpha,dur);
                    Triangle(prevN, cf, prevF, r,g,b,alpha,dur);
                }
            }
            prevN = cn; prevF = cf; hasPrev = true;
        }
        _BatchFlush();
    }

    void Cone(const Vector&in apex, const Vector&in dir, float length, float halfAngleDeg,
            const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Cone(apex, dir, length, halfAngleDeg, color[0], color[1], color[2], alpha, dur, segments);
    }

    void Cone(const Vector&in eyePos, const Vector&in fwd, const Vector&in right, const Vector&in up,
              float near, float far, float halfAngleDeg,
              const Color&in color, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Cone(eyePos, fwd, right, up, near, far, halfAngleDeg, color[0],color[1],color[2], alpha, dur, segments);
    }

    void Cone(const Vector&in eyePos, const QAngle&in angles,
          float nearDist, float farDist, float halfAngleDeg,
          int r, int g, int b, int alpha = 0, float dur = 0.05f, float segments = 16)
    {
        Vector fwd, right, up;
        AngleVectors(angles, fwd, right, up);
        
        Cone(eyePos, fwd, right, up, nearDist, farDist, halfAngleDeg, r, g, b, alpha, dur, segments);
    }




    // ==============================================
    //
    //  ARROW
    //
    // ==============================================

    void ThickArrow(const Vector&in start, const Vector&in end, 
                float width = 8.0f,
                float headSize = 2.0f,
                int r = 255, int g = 255, int b = 255,
                float duration = 0.05f)
    {
        Vector dir = end - start;
        float length = dir.Length();
        if (length < 0.001f) return;
        dir /= length;

        Vector right = dir.Cross(Vector(0, 0, 1)).Normalized();
        if (right.Length() < 0.01f)
            right = dir.Cross(Vector(1, 0, 0)).Normalized();

        float halfWidth = width * 0.5f;
        float headLength = width * headSize;

        if (headLength > length * 0.7f)
            headLength = length * 0.7f;

        Vector shaftEnd = end - dir * headLength;

        Vector p1 = start  - right * halfWidth;
        Vector p2 = shaftEnd - right * halfWidth;
        Vector p3 = shaftEnd + right * halfWidth;
        Vector p4 = start  + right * halfWidth;

        Vector p5 = shaftEnd - right * (halfWidth * 2.0f);
        Vector p6 = shaftEnd + right * (halfWidth * 2.0f);
        Vector p7 = end;                                    

        _BatchBegin();

        Line(p1, p2, r, g, b, duration);
        Line(p2, p3, r, g, b, duration);
        Line(p3, p4, r, g, b, duration);
        Line(p4, p1, r, g, b, duration);

        Line(p5, p7, r, g, b, duration);
        Line(p6, p7, r, g, b, duration);
        Line(p5, p6, r, g, b, duration);

        _BatchFlush();
    }


    void ThickArrow(const Vector&in start, const Vector&in end, float width,
                    int r, int g, int b, float duration = 0.05f)
    {
        ThickArrow(start, end, width, 2.0f, r, g, b, duration);
    }


    void ThickArrow(const Vector&in start, const Vector&in end, float width,
                    const Color&in color, float duration = 0.05f)
    {
        ThickArrow(start, end, width, color[0], color[1], color[2], duration);
    }

    void ThickArrow(const Vector&in start, const Vector&in end, 
                float width, float headSize,
                const Color&in color, float duration = 0.05f)
    {
        ThickArrow(start, end, width, headSize, 
                color[0], color[1], color[2], duration);
    }


    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                      float width = 8.0f,
                      float headSize = 2.0f,
                      int r = 255, int g = 255, int b = 255,
                      float duration = 0.05f)
    {
        Vector dir = end - start;
        float length = dir.Length();
        if (length < 0.001f) return;
        dir /= length;

        Vector right = dir.Cross(Vector(0, 0, 1)).Normalized();
        if (right.Length() < 0.01f)
            right = dir.Cross(Vector(1, 0, 0)).Normalized();

        float halfWidth = width * 0.5f;
        float headLength = width * headSize;

        float maxHeadLength = length * 0.35f;
        if (headLength > maxHeadLength)
            headLength = maxHeadLength;

        Vector shaftStart = start + dir * headLength;
        Vector shaftEnd   = end   - dir * headLength;

        Vector p1 = shaftStart - right * halfWidth;
        Vector p2 = shaftEnd   - right * halfWidth;
        Vector p3 = shaftEnd   + right * halfWidth;
        Vector p4 = shaftStart + right * halfWidth;

        Vector p5 = shaftEnd - right * (halfWidth * 2.0f);
        Vector p6 = shaftEnd + right * (halfWidth * 2.0f);
        Vector p7 = end;

        Vector p8  = shaftStart + right * (halfWidth * 2.0f);
        Vector p9  = shaftStart - right * (halfWidth * 2.0f);
        Vector p10 = start;

        _BatchBegin();

        Line(p1, p2, r, g, b, duration);
        Line(p2, p3, r, g, b, duration);
        Line(p3, p4, r, g, b, duration);
        Line(p4, p1, r, g, b, duration);

        Line(p5, p7, r, g, b, duration);
        Line(p6, p7, r, g, b, duration);
        Line(p5, p6, r, g, b, duration);

        Line(p8, p10, r, g, b, duration);
        Line(p9, p10, r, g, b, duration);
        Line(p8, p9, r, g, b, duration);

        _BatchFlush();
    }
    
    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width, float headSize,
                        const Color&in color, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, headSize, 
                        color[0], color[1], color[2], duration);
    }

    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width,
                        const Color&in color, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, 2.0f, color, duration);
    }


    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                      float width = 8.0f,
                      float headSizeStart = 2.0f,
                      float headSizeEnd   = 2.0f, 
                      int r = 255, int g = 255, int b = 255,
                      float duration = 0.05f)
    {
        Vector dir = end - start;
        float length = dir.Length();
        if (length < 0.001f) return;
        dir /= length;

        Vector right = dir.Cross(Vector(0, 0, 1)).Normalized();
        if (right.Length() < 0.01f)
            right = dir.Cross(Vector(1, 0, 0)).Normalized();

        float halfWidth = width * 0.5f;

        float maxHead = length * 0.45f;
        float headLengthStart = _min(width * headSizeStart, maxHead);
        float headLengthEnd   = _min(width * headSizeEnd,   maxHead);

        Vector shaftStart = start + dir * headLengthStart;
        Vector shaftEnd   = end   - dir * headLengthEnd;

        Vector p1 = shaftStart - right * halfWidth;
        Vector p2 = shaftEnd   - right * halfWidth;
        Vector p3 = shaftEnd   + right * halfWidth;
        Vector p4 = shaftStart + right * halfWidth;

        Vector p5 = shaftEnd - right * (halfWidth * 2.0f);
        Vector p6 = shaftEnd + right * (halfWidth * 2.0f);
        Vector p7 = end;

        Vector p8 = shaftStart + right * (halfWidth * 2.0f);
        Vector p9 = shaftStart - right * (halfWidth * 2.0f);
        Vector p10 = start;

        _BatchBegin();

        Line(p1, p2, r, g, b, duration);
        Line(p2, p3, r, g, b, duration);
        Line(p3, p4, r, g, b, duration);
        Line(p4, p1, r, g, b, duration);

        Line(p5, p7, r, g, b, duration);
        Line(p6, p7, r, g, b, duration);
        Line(p5, p6, r, g, b, duration);

        Line(p8, p10, r, g, b, duration);
        Line(p9, p10, r, g, b, duration);
        Line(p8, p9, r, g, b, duration);

        _BatchFlush();
    }

    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width, float headSizeStart, float headSizeEnd,
                        const Color&in color, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, headSizeStart, headSizeEnd,
                        color[0], color[1], color[2], duration);
    }




    // ==============================================
    //
    //  TORUS
    //
    // ==============================================


    void Torus(const Vector&in center, 
           const Vector&in normal, 
           float majorRadius,
           float minorRadius,
           int r, int g, int b, 
           int alpha = 0,
           float dur = 0.05f, 
           float segments = 24,
           float sides = 12)
    {
        if (majorRadius <= 0.0f || minorRadius <= 0.0f) return;

        Vector n = normal.Normalized();
        
        Vector arb = Vector(0,0,1);
        if (fabs(n.z) > 0.98f) arb = Vector(1,0,0);
        
        Vector right = n.Cross(arb).Normalized();
        Vector forward = n.Cross(right);

        float majorStep = 6.283185f / segments;
        float minorStep = 6.283185f / sides;

        _BatchBegin();

        for (int i = 0; i < segments; i++)
        {
            float a1 = float(i) * majorStep;
            float a2 = float(i + 1) * majorStep;

            float ca1 = cos(a1), sa1 = sin(a1);
            float ca2 = cos(a2), sa2 = sin(a2);

            Vector c1 = center + right * (ca1 * majorRadius) + forward * (sa1 * majorRadius);
            Vector c2 = center + right * (ca2 * majorRadius) + forward * (sa2 * majorRadius);

            for (int j = 0; j < sides; j++)
            {
                float b1 = float(j) * minorStep;
                float b2 = float(j + 1) * minorStep;

                float cb1 = cos(b1), sb1 = sin(b1);
                float cb2 = cos(b2), sb2 = sin(b2);

                Vector p1 = c1 + (right * ca1 + forward * sa1) * (minorRadius * cb1) + n * (minorRadius * sb1);
                Vector p2 = c1 + (right * ca1 + forward * sa1) * (minorRadius * cb2) + n * (minorRadius * sb2);
                Vector p3 = c2 + (right * ca2 + forward * sa2) * (minorRadius * cb2) + n * (minorRadius * sb2);
                Vector p4 = c2 + (right * ca2 + forward * sa2) * (minorRadius * cb1) + n * (minorRadius * sb1);

                if (alpha <= 0)
                {
                    _bLine(p1, p2, r, g, b, dur);
                    _bLine(p2, p3, r, g, b, dur);
                }
                else
                {
                    Triangle(p1, p2, p3, r, g, b, alpha, dur);
                    Triangle(p1, p3, p4, r, g, b, alpha, dur);
                }
            }
        }

        _BatchFlush();
    }

    void Torus(const Vector&in center, const Vector&in normal,
            float majorRadius, float minorRadius,
            const Color&in color, int alpha = 0,
            float dur = 0.05f, float segments = 24, float sides = 12)
    {
        Torus(center, normal, majorRadius, minorRadius,
            color[0], color[1], color[2], alpha, dur, segments, sides);
    }




    // ==============================================
    //
    //  HELIX
    //
    // ==============================================


    void Helix(const Vector&in start, const Vector&in dir,
           float length, float radius,
           float turns,
           int r, int g, int b,
           float dur = 0.05f, float segments = 64)
    {
        if (length <= 0 || radius <= 0) return;

        Vector forward = dir.Normalized();
        
        Vector arb = Vector(0,0,1);
        if (fabs(forward.z) > 0.98f) arb = Vector(1,0,0);
        
        Vector right = forward.Cross(arb).Normalized();
        Vector up    = forward.Cross(right);

        float step = (turns * 6.283185f) / segments;
        float heightStep = length / segments;

        Vector prev = start;

        _BatchBegin();

        for (int i = 1; i <= segments; i++)
        {
            float angle = float(i) * step;
            float h = float(i) * heightStep;

            Vector offset = right * (cos(angle) * radius) + up * (sin(angle) * radius);
            Vector current = start + forward * h + offset;


            _bLine(prev, current, r, g, b, dur);
            

            prev = current;
        }

        _BatchFlush();
    }

    void Helix(const Vector&in start, const Vector&in dir,
            float length, float radius, float turns,
            const Color&in color,
            float dur = 0.05f, float segments = 64)
    {
        Helix(start, dir, length, radius, turns, color[0], color[1], color[2], dur, segments);
    }




    // ==============================================
    //
    //  ANGLE
    //
    // ==============================================


    private float SafeAcos(float dot)
    {
        if (dot > 1.0f) dot = 1.0f;
        if (dot < -1.0f) dot = -1.0f;
        return acos(dot);
    }

    void Angle(const Vector&in center,
            const Vector&in normal,
            const Vector&in dir1,
            const Vector&in dir2,
            float radius,
            int r, int g, int b, int alpha = 0,
            float dur = 0.05f, float segments = 24)
    {
        Vector n  = normal.Normalized();
        Vector d1 = dir1.Normalized();
        Vector d2 = dir2.Normalized();

        float angleDeg = SafeAcos(d1.Dot(d2)) * RAD2DEG;

        Arc(center, n, d1, radius, angleDeg, r, g, b, alpha, dur, segments);
        Line(center, center + d1 * radius * 1.15f, r, g, b, dur);
        Line(center, center + d2 * radius * 1.15f, r, g, b, dur);
        Text(center + n * 2.0f + Vector(0, 0, 10), "Angle: " + angleDeg, dur);
    }

    void Angle(const Vector&in center,
            const Vector&in normal,
            const Vector&in dir1,
            const Vector&in dir2,
            float radius,
            const Color&in color, int alpha = 0,
            float dur = 0.05f, float segments = 24)
    {
        Angle(center, normal, dir1, dir2, radius,
            color[0], color[1], color[2], alpha, dur, segments);
    }

    void Angle(const Vector&in center,
            const Vector&in point1,
            const Vector&in point2,
            float radius = 20.0f,
            int r = 255, int g = 200, int b = 100, int alpha = 0,
            float dur = 0.1f, float segments = 24)
    {
        Vector d1 = (point1 - center).Normalized();
        Vector d2 = (point2 - center).Normalized();

        Vector normal = d1.Cross(d2);
        normal = (normal.Length() < 0.001f) ? Vector(0, 0, 1) : normal.Normalized();

        float angleDeg = SafeAcos(d1.Dot(d2)) * RAD2DEG;

        Arc(center, normal, d1, radius, angleDeg, r, g, b, alpha, dur, segments);
        Line(center, center + d1 * radius * 1.2f, r, g, b, dur);
        Line(center, center + d2 * radius * 1.2f, r, g, b, dur);
        Text(center + normal * (radius * 0.6f), "Angle: " + angleDeg, dur);
    }

    void Angle(const Vector&in center,
            const Vector&in point1,
            const Vector&in point2,
            const Color&in color,
            float radius = 20.0f,
            float dur = 0.1f, float segments = 24)
    {
        Angle(center, point1, point2, radius,
            color[0], color[1], color[2], 0, dur, segments);
    }




    // ==============================================
    //
    //  PYRAMID / TETRAHEDRON
    //
    // ==============================================


    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                float rotDeg,
                int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Vector up = dir.Normalized();

        Vector arb = Vector(0, 0, 1);
        if (fabs(up.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right   = up.Cross(arb).Normalized();
        Vector forward = up.Cross(right);

        float rad = rotDeg * DEG2RAD;
        float cr = cos(rad), sr = sin(rad);
        Vector r2 =  right * cr + forward * sr;
        Vector f2 = -right * sr + forward * cr;

        float hw = size.x * 0.5f;
        float hd = size.y * 0.5f;
        float h  = size.z;

        Vector b0 = origin + r2 *  hw + f2 *  hd;
        Vector b1 = origin + r2 *  hw + f2 * -hd;
        Vector b2 = origin + r2 * -hw + f2 * -hd;
        Vector b3 = origin + r2 * -hw + f2 *  hd;

        Vector apex = origin + up * h;

        _BatchBegin();

        if (alpha <= 0)
        {
            _bLine(b0, b1, r, g, b, dur);
            _bLine(b1, b2, r, g, b, dur);
            _bLine(b2, b3, r, g, b, dur);
            _bLine(b3, b0, r, g, b, dur);

            _bLine(b0, apex, r, g, b, dur);
            _bLine(b1, apex, r, g, b, dur);
            _bLine(b2, apex, r, g, b, dur);
            _bLine(b3, apex, r, g, b, dur);
        }
        else
        {
            TriangleInv(b0, b1, b2, r, g, b, alpha, dur);
            TriangleInv(b0, b2, b3, r, g, b, alpha, dur);

            Triangle(b0, b1, apex, r, g, b, alpha, dur);
            Triangle(b1, b2, apex, r, g, b, alpha, dur);
            Triangle(b2, b3, apex, r, g, b, alpha, dur);
            Triangle(b3, b0, apex, r, g, b, alpha, dur);
        }

        _BatchFlush();
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                float rotDeg,
                const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, rotDeg, color[0], color[1], color[2], alpha, dur);
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, 0.0f, r, g, b, alpha, dur);
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, 0.0f, color[0], color[1], color[2], alpha, dur);
    }


    void Tetrahedron(const Vector&in center, const Vector&in dir,
                    float radius,
                    int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Vector up = dir.Normalized();

        Vector arb = Vector(0, 0, 1);
        if (fabs(up.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right   = up.Cross(arb).Normalized();
        Vector forward = up.Cross(right);

        float baseH  = -radius / 3.0f;
        float baseR  =  radius * 0.9428f;

        Vector apex = center + up * radius;

        Vector v0 = center + up * baseH + right   *  baseR;
        Vector v1 = center + up * baseH + right   * (baseR * -0.5f) + forward * (baseR *  0.8660f);
        Vector v2 = center + up * baseH + right   * (baseR * -0.5f) + forward * (baseR * -0.8660f);

        _BatchBegin();

        if (alpha <= 0)
        {
            _bLine(v0, v1,   r, g, b, dur);
            _bLine(v1, v2,   r, g, b, dur);
            _bLine(v2, v0,   r, g, b, dur);

            _bLine(v0, apex, r, g, b, dur);
            _bLine(v1, apex, r, g, b, dur);
            _bLine(v2, apex, r, g, b, dur);
        }
        else
        {
            TriangleInv(v0, v1, v2, r, g, b, alpha, dur);

            Triangle(v0, v1, apex, r, g, b, alpha, dur);
            Triangle(v1, v2, apex, r, g, b, alpha, dur);
            Triangle(v2, v0, apex, r, g, b, alpha, dur);
        }

        _BatchFlush();
    }

    void Tetrahedron(const Vector&in center, const Vector&in dir,
                    float radius,
                    const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Tetrahedron(center, dir, radius, color[0], color[1], color[2], alpha, dur);
    }




    // ==============================================
    //
    //  PRISM / TUBE
    //
    // ==============================================


    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            float rotDeg,
            int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Vector fwd = dir.Normalized();

        Vector arb = Vector(0, 0, 1);
        if (fabs(fwd.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right = fwd.Cross(arb).Normalized();
        Vector up    = fwd.Cross(right);

        float rad = rotDeg * DEG2RAD;
        float cr = cos(rad), sr = sin(rad);
        Vector r2 =  right * cr + up * sr;
        Vector u2 = -right * sr + up * cr;

        float hw = size.x * 0.5f;
        float hh = size.y * 0.5f;


        Vector t0 = r2 *  0.0f  + u2 *  hh;
        Vector t1 = r2 *  hw    + u2 * -hh;
        Vector t2 = r2 * -hw    + u2 * -hh;

        Vector s0 = origin         + t0;
        Vector s1 = origin         + t1;
        Vector s2 = origin         + t2;

        Vector e0 = origin + fwd * length + t0;
        Vector e1 = origin + fwd * length + t1;
        Vector e2 = origin + fwd * length + t2;

        _BatchBegin();

        if (alpha <= 0)
        {
            _bLine(s0, s1, r, g, b, dur);
            _bLine(s1, s2, r, g, b, dur);
            _bLine(s2, s0, r, g, b, dur);

            _bLine(e0, e1, r, g, b, dur);
            _bLine(e1, e2, r, g, b, dur);
            _bLine(e2, e0, r, g, b, dur);

            _bLine(s0, e0, r, g, b, dur);
            _bLine(s1, e1, r, g, b, dur);
            _bLine(s2, e2, r, g, b, dur);
        }
        else
        {
            TriangleInv(s0, s1, s2, r, g, b, alpha, dur);

            Triangle(e0, e1, e2, r, g, b, alpha, dur);

            TriangleInv(s0, s1, e1, r, g, b, alpha, dur);
            TriangleInv(s0, e1, e0, r, g, b, alpha, dur);

            Triangle(s1, s2, e2, r, g, b, alpha, dur);
            Triangle(s1, e2, e1, r, g, b, alpha, dur);

            TriangleInv(s2, s0, e0, r, g, b, alpha, dur);
            TriangleInv(s2, e0, e2, r, g, b, alpha, dur);
        }

        _BatchFlush();
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            float rotDeg,
            const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, rotDeg,
            color[0], color[1], color[2], alpha, dur);
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, 0.0f, r, g, b, alpha, dur);
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, 0.0f,
            color[0], color[1], color[2], alpha, dur);
    }


    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float innerRadius,
            int r, int g, int b, int alpha = 0,
            float dur = 0.05f, float segments = 16)
    {
        if (outerRadius <= 0.0f) return;
        if (innerRadius < 0.0f)  innerRadius = 0.0f;
        if (innerRadius >= outerRadius) innerRadius = outerRadius * 0.5f;

        Vector dir = end - start;
        float len = dir.Length();
        if (len < 0.001f) return;
        dir /= len;

        Vector arb = Vector(0, 0, 1);
        if (fabs(dir.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right = dir.Cross(arb).Normalized();
        Vector up    = dir.Cross(right);

        float step = 6.283185f / segments;

        _BatchBegin();

        Vector prevSO, prevEO;   // outer start/end
        Vector prevSI, prevEI;   // inner start/end
        bool hasPrev = false;

        for (int i = 0; i <= segments; i++)
        {
            float angle = float(i) * step;
            float ca = cos(angle), sa = sin(angle);

            Vector offsetO = right * (ca * outerRadius) + up * (sa * outerRadius);
            Vector offsetI = right * (ca * innerRadius) + up * (sa * innerRadius);

            Vector sO = start + offsetO;
            Vector eO = end   + offsetO;
            Vector sI = start + offsetI;
            Vector eI = end   + offsetI;

            if (hasPrev)
            {
                if (alpha <= 0)
                {
                    _bLine(prevSO, sO, r, g, b, dur);
                    _bLine(prevEO, eO, r, g, b, dur);
                    _bLine(sO, eO,    r, g, b, dur);

                    _bLine(prevSI, sI, r, g, b, dur);
                    _bLine(prevEI, eI, r, g, b, dur);
                    _bLine(sI, eI,    r, g, b, dur);

                    _bLine(prevSO, prevSI, r, g, b, dur);
                    _bLine(prevEO, prevEI, r, g, b, dur);
                }
                else
                {
                    TriangleInv(prevSO, sO, eO,    r, g, b, alpha, dur);
                    TriangleInv(prevSO, eO, prevEO, r, g, b, alpha, dur);

                    Triangle(prevSI, sI, eI,    r, g, b, alpha, dur);
                    Triangle(prevSI, eI, prevEI, r, g, b, alpha, dur);

                    TriangleInv(prevSO, sO, sI,    r, g, b, alpha, dur);
                    TriangleInv(prevSO, sI, prevSI, r, g, b, alpha, dur);

                    Triangle(prevEO, eO, eI,    r, g, b, alpha, dur);
                    Triangle(prevEO, eI, prevEI, r, g, b, alpha, dur);
                }
            }

            prevSO = sO; prevEO = eO;
            prevSI = sI; prevEI = eI;
            hasPrev = true;
        }

        _BatchFlush();
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float innerRadius,
            const Color&in color, int alpha = 0,
            float dur = 0.05f, float segments = 16)
    {
        Tube(start, end, outerRadius, innerRadius,
            color[0], color[1], color[2], alpha, dur, segments);
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float wallThickness,
            bool useThickness,
            int r, int g, int b, int alpha = 0,
            float dur = 0.05f, float segments = 16)
    {
        float inner = useThickness
            ? _max(0.0f, outerRadius - wallThickness)
            : wallThickness;

        Tube(start, end, outerRadius, inner, r, g, b, alpha, dur, segments);
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float wallThickness,
            bool useThickness,
            const Color&in color, int alpha = 0,
            float dur = 0.05f, float segments = 16)
    {
        Tube(start, end, outerRadius, wallThickness, useThickness,
            color[0], color[1], color[2], alpha, dur, segments);
    }




    // ==============================================
    //
    //  VELOCITY / ACCELERATION ARROWS
    //
    // ==============================================


    // ----------------------------------------------
    //  VelocityArrow
    //
    //  origin    — the point of application
    //  velocity  — the velocity vector (direction + magnitude)
    //  scale     — the scale of the arrow's length
    // ----------------------------------------------

    void VelocityArrow(const Vector&in origin, const Vector&in velocity,
                    float scale = 1.0f,
                    int r = 80, int g = 200, int b = 80,
                    float dur = 0.05f, float headSize = 6.0f)
    {
        float speed = velocity.Length();
        if (speed < 0.001f) return;

        Vector tip = origin + velocity * scale;

        Arrow(origin, tip, r, g, b, dur, headSize);

        Text(tip + Vector(0, 0, 8), "v: " + _truncf(speed), dur);
    }

    void VelocityArrow(const Vector&in origin, const Vector&in velocity,
                    float scale,
                    const Color&in color,
                    float dur = 0.05f, float headSize = 6.0f)
    {
        VelocityArrow(origin, velocity, scale,
                    color[0], color[1], color[2], dur, headSize);
    }


    // ----------------------------------------------
    //  AccelerationArrow
    //
    //  origin       — the point of application
    //  acceleration — the acceleration vector
    //  scale        — the scale of the arrow's length
    // ----------------------------------------------

    void AccelerationArrow(const Vector&in origin, const Vector&in acceleration,
                        float scale = 1.0f,
                        int r = 255, int g = 140, int b = 0,
                        float dur = 0.05f, float headSize = 6.0f)
    {
        float mag = acceleration.Length();
        if (mag < 0.001f) return;

        Vector tip = origin + acceleration * scale;

        Arrow(origin, tip, r, g, b, dur, headSize);

        Text(tip + Vector(0, 0, 8), "a: " + _truncf(mag), dur);
    }

    void AccelerationArrow(const Vector&in origin, const Vector&in acceleration,
                        float scale,
                        const Color&in color,
                        float dur = 0.05f, float headSize = 6.0f)
    {
        AccelerationArrow(origin, acceleration, scale,
                        color[0], color[1], color[2], dur, headSize);
    }


    // ----------------------------------------------
    //  VelocityAccelerationArrows
    //
    //  Plots both vectors together — velocity in green,
    //  acceleration in orange, plus the projection of the acceleration
    //  onto the velocity as a dotted line
    // ----------------------------------------------

    void VelocityAccelerationArrows(const Vector&in origin,
                                    const Vector&in velocity,
                                    const Vector&in acceleration,
                                    float velScale = 1.0f,
                                    float accScale = 1.0f,
                                    float dur = 0.05f)
    {
        float speed = velocity.Length();
        float accMag = acceleration.Length();

        VelocityArrow(origin, velocity, velScale,
                    DebugRendererColors::GREEN, dur);

        AccelerationArrow(origin, acceleration, accScale,
                        DebugRendererColors::ORANGE, dur);

        if (speed > 0.001f && accMag > 0.001f)
        {
            Vector velDir = velocity / speed;
            float  proj   = acceleration.Dot(velDir);
            Vector aTan   = velDir * proj;
            Vector aNorm  = acceleration - aTan;

            Vector tipTan  = origin + aTan  * accScale;
            Vector tipNorm = origin + aNorm * accScale;

            _DrawDashedLine(origin, tipTan,
                            DebugRendererColors::YELLOW[0],
                            DebugRendererColors::YELLOW[1],
                            DebugRendererColors::YELLOW[2], dur);

            _DrawDashedLine(origin, tipNorm,
                            DebugRendererColors::CYAN[0],
                            DebugRendererColors::CYAN[1],
                            DebugRendererColors::CYAN[2], dur);

            Text(tipTan  + Vector(0,0,8), "a_tan: "  + _truncf(proj),        dur);
            Text(tipNorm + Vector(0,0,8), "a_norm: " + _truncf(aNorm.Length()), dur);
        }

        Text(origin + Vector(0, 0, 20),
            "spd=" + _truncf(speed) + " acc=" + _truncf(accMag), dur);
    }


    // ----------------------------------------------
    //  Guideline
    // ----------------------------------------------

    void _DrawDashedLine(const Vector&in from, const Vector&in to,
                                int r, int g, int b,
                                float dur = 0.05f,
                                float dashLen = 6.0f, float gapLen = 4.0f)
    {
        Vector dir = to - from;
        float  total = dir.Length();
        if (total < 0.001f) return;
        dir /= total;

        float t = 0.0f;
        bool  drawing = true;

        _BatchBegin();

        while (t < total)
        {
            float segLen = drawing ? dashLen : gapLen;
            float tEnd   = _min(t + segLen, total);

            if (drawing)
                _bLine(from + dir * t, from + dir * tEnd, r, g, b, dur);

            t       = tEnd;
            drawing = !drawing;
        }

        _BatchFlush();
    }

    void _DrawDashedLine(const Vector&in from, const Vector&in to,
                        const Color&in color,
                        float dur = 0.05f,
                        float dashLen = 6.0f, float gapLen = 4.0f)
    {
        _DrawDashedLine(from, to, color[0], color[1], color[2], dur, dashLen, gapLen);
    }




    // ==============================================
    //
    //  BASIS
    //
    // ==============================================


    // ----------------------------------------------
    //  Transform – three axes
    // ----------------------------------------------

    // Plots the X/Y/Z axes from the origin using the basis vectors
    void Basis(const Vector&in origin,
               const Vector&in fwd, const Vector&in right, const Vector&in up,
               float scale = 20.0f, float dur = 0.05f)
    {
        _BatchBegin();
        _bLine(origin, origin + fwd   * scale, DebugRendererColors::AXIS_X[0], DebugRendererColors::AXIS_X[1], DebugRendererColors::AXIS_X[2], dur);
        _bLine(origin, origin + right * scale, DebugRendererColors::AXIS_Y[0], DebugRendererColors::AXIS_Y[1], DebugRendererColors::AXIS_Y[2], dur);
        _bLine(origin, origin + up    * scale, DebugRendererColors::AXIS_Z[0], DebugRendererColors::AXIS_Z[1], DebugRendererColors::AXIS_Z[2], dur);
        _BatchFlush();
    }

    // Overloading for QAngle — it will break it down into vectors itself
    void Basis(const Vector&in origin, const QAngle&in angles,
               float scale = 20.0f, float dur = 0.05f)
    {
        Vector fwd, right, up;
        AngleVectors(angles, fwd, right, up);
        Basis(origin, fwd, right, up, scale, dur);
    }



    
    // ==============================================
    //
    //  TEXT
    //
    // ==============================================


    void Text(const Vector&in pos, const string&in text, float dur = 0.05f)
    {
        _exec("DebugDrawText(" + _v(pos) + ",\"" + _escape(text) + "\",false," + dur + ")");
    }


    void ScreenText(float x, float y, const string&in text,
                    int r = 255, int g = 255, int b = 255, int a = 255,
                    float dur = 0.05f)
    {
        _exec("DebugDrawScreenText(" + x + "," + y + ",\"" + 
            _escape(text) + "\"," + r + "," + g + "," + b + "," + a + "," + dur + ")");
    }


    void EntityText(int entityID, int textOffset, const string&in text,
                    float dur = 0.05f, int r = 255, int g = 255, int b = 255, int a = 255)
    {
        _exec("DebugDrawEntityText(" + entityID + "," + textOffset + ",\"" + 
            _escape(text) + "\"," + dur + "," + r + "," + g + "," + b + "," + a + ")");
    }

    void EntityTextAtPos(const Vector&in pos, int textOffset, const string&in text,
                        float dur = 0.05f, int r = 255, int g = 255, int b = 255, int a = 255)
    {
        _exec("DebugDrawEntityTextAtPosition(" + _v(pos) + "," + textOffset + ",\"" + 
            _escape(text) + "\"," + dur + "," + r + "," + g + "," + b + "," + a + ")");
    }


    void TextFloat(const Vector&in pos, const string&in label, float value, float dur = 0.05f)
    {
        Text(pos, label + ": " + _truncf(value), dur);
    }

    void TextInt(const Vector&in pos, const string&in label, int value, float dur = 0.05f)
    {
        Text(pos, label + ": " + value, dur);
    }

    void TextVec(const Vector&in pos, const string&in label, const Vector&in value, float dur = 0.05f)
    {
        Text(pos, label + ": (" + _truncf(value.x) + ", " + 
                        _truncf(value.y) + ", " + 
                        _truncf(value.z) + ")", dur);
    }




    // ==============================================
    //
    // 
    //
    // ==============================================


    // ----------------------------------------------
    //  Batch system
    // ----------------------------------------------

    private string m_batch = "";

    void _BatchBegin()  { m_batch = ""; }

    void _bLine(const Vector&in a, const Vector&in b,
                int r, int g, int bv, float dur)
    {
        m_batch += "DebugDrawLine(" +
                   _v(a) + "," + _v(b) + "," +
                   r + "," + g + "," + bv + ",false," + dur + ");";
    }

    void _BatchFlush()
    {
        if (m_batch.length() > 0)
        {
            _exec(m_batch);
            m_batch = "";
        }
    }


    // ----------------------------------------------
    //  Internal utilities
    // ----------------------------------------------

    private float _max(float a, float b)
    {
        return (a > b) ? a : b;
    }

    private int _max(int a, int b)
    {
        return (a > b) ? a : b;
    }

    private float _min(float a, float b)
    {
        return (a < b) ? a : b;
    }

    private int _min(int a, int b)
    {
        return (a < b) ? a : b;
    }

    private string _v(const Vector&in v) const
    {
        return "Vector(" + v.x + "," + v.y + "," + v.z + ")";
    }

    private string _v(const QAngle&in a)
    {
        return "Vector(" + a.x + "," + a.y + "," + a.z + ")";
    }

    // Truncates float to 2 decimal places for readable text
    private string _truncf(float f) const
    {
        int i  = int(f);
        int fr = int(abs(f - float(i)) * 100.0f);
        return i + "." + (fr < 10 ? "0" : "") + fr;
    }

    // Escapes quotes in a string to prevent breaking RunScriptCode
    private string _escape(const string&in s) const
    {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");

    }

    private void _exec(const string&in code)
    {
        if (m_logic is null) return;

        m_variant.SetString(code);
        m_logic.FireInput("RunScriptCode", m_variant, 0.0f, null, m_owner);
    }
}
