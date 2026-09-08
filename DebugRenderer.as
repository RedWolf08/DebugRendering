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


// ----------------------------------------------
//  Internal utilities
// ----------------------------------------------

namespace Internal {
    float _max(float a, float b)
    {
        return (a > b) ? a : b;
    }
    int _max(int a, int b)
    {
        return (a > b) ? a : b;
    }
    float _min(float a, float b)
    {
        return (a < b) ? a : b;
    }
    int _min(int a, int b)
    {
        return (a < b) ? a : b;
    }
    // Truncates float to 2 decimal places for readable text
    string _truncf(float f)
    {
        int i  = int(f);
        int fr = int(abs(f - float(i)) * 100.0f);
        return i + "." + (fr < 10 ? "0" : "") + fr;
    }
    // ----------------------------------------------
    //  Arrow Head (helper for Arrow and DoubleArrow)
    // ----------------------------------------------
    float SafeAcos(float dot)
    {
        if (dot > 1.0f) dot = 1.0f;
        if (dot < -1.0f) dot = -1.0f;
        return acos(dot);
    }

    void _ArrowHeadCone(const Vector&in tip, const Vector&in dir,
                            float headLength, float headWidth,
                            int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f,
                            float segments = 12)
    {
        if (headLength <= 0.0f) return;
        Vector baseCenter = tip - dir * headLength;
        
        float halfAngle = atan(headWidth / headLength);
        
        debug::Cone(tip, dir * -1.0f, halfAngle, headLength,  r, g, b, alpha, ignoreZ, dur);
        if (alpha > 0)
        {
            // CHECK THIS LATER
            debug::Disk(baseCenter, -dir, headWidth, r, g, b, alpha, ignoreZ, false, dur, segments);
        }
        else
        {
            debug::Disk(baseCenter, -dir, headWidth, r, g, b, 0, ignoreZ, false, dur, segments);
        }
    }
}

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

namespace debug
{

    // ==============================================
    //
    //  Primitives — overloads with presets
    //
    // ==============================================


    void Line(const Vector&in pa, const Vector&in pb,
              const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Line(pa, pb, color[0], color[1], color[2], ignoreZ, dur);
    }

    void Circle(const Vector&in origin, float radius,
            const Color&in color, int alpha = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Circle(origin, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Circle(const Vector&in origin, const Vector&in xAxis, const Vector&in yAxis, float radius,
            const Color&in color, int alpha = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Circle(origin, xAxis, yAxis, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Circle(const Vector&in origin, const QAngle&in angles, float radius,
            const Color&in color, int alpha = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Circle(origin, angles, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Circle(const Vector&in origin, const Vector&in normal, float radius,
            const Color&in color, int alpha = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        QAngle ang;
        VectorAngles(normal, ang);
        Circle(origin, ang, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
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
            bool ignoreZ = false,             
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

        for (int i = 1; i <= segments; i++)
        {
            currentAngle = float(i) * step;
            
            float ca = cos(currentAngle);
            float sa = sin(currentAngle);

            Vector current = center + (right * sa + up * ca) * radius;

            if (alpha <= 0)
            {
                Line(prev, current, r, g, b, ignoreZ, dur);
            }
            else
            {
                Triangle(center, prev, current, r, g, b, alpha, ignoreZ, dur);
            }

            prev = current;
        }

    }

    void Arc(const Vector&in center, 
            const Vector&in normal, 
            const Vector&in startDir, 
            float radius,
            float angleDegrees,
            const Color&in color, 
            int alpha = 0, 
            bool ignoreZ = false,
            float dur = 0.05f, 
            float segments = 24)
    {
         Arc(center, normal, startDir, radius, angleDegrees, 
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }


    void ArcBetween(const Vector&in center, const Vector&in normal,
                const Vector&in startDir, const Vector&in endDir,
                float radius, int r, int g, int b, int alpha = 0,
                bool ignoreZ = false, float dur = 0.05f, float segments = 24)
    {
        Vector pa = startDir.Normalized();
        Vector pb = endDir.Normalized();
        
        float angle = acos(pa.Dot(pb)) * RAD2DEG;
        if (angle < 0.1f) angle = 0.1f;
        
         Arc(center, normal, pa, radius, angle, r, g, b, alpha, ignoreZ, dur, segments);
    }

    void ArcBetween(const Vector&in center, const Vector&in normal,
                const Vector&in startDir, const Vector&in endDir,
                float radius, const Color&in color, int alpha = 0, 
                bool ignoreZ = false, float dur = 0.05f, float segments = 24)
    {
         ArcBetween(center, normal, startDir, endDir, radius, 
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }


    void Triangle(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                const Color&in color, int a = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Triangle(p1, p2, p3, color[0], color[1], color[2], a, ignoreZ, dur);
    }


    void TriangleInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                 int r, int g, int b, int a = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Triangle(p1, p3, p2, r, g, b, a, ignoreZ, dur); 
    }

    void TriangleInv(const Vector&in p1, const Vector&in p2, const Vector&in p3,
                 const Color&in color, int a = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        Triangle(p1, p3, p2, color[0], color[1], color[2], a, ignoreZ, dur);
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

    void BoxDirection(const Vector&in origin,
                const Vector&in mins, const Vector&in maxs,
                const Vector&in forward,
                const Color&in color, int alpha = 0, float dur = 0.05f)
    {
	    BoxDirection(origin, mins, maxs, forward, color[0], color[1], color[2], alpha, dur);
    }

    void BoxDirection(const Vector&in center, const Vector&in size, const Vector&in forward, 
          int r, int g, int b, int alpha = 0, float dur = 0.05f)
    {
        Vector mins = size * -0.5f;
        Vector maxs = size * 0.5f;
        BoxDirection(center, mins, maxs, forward, r, g, b, alpha, dur);
    }

    void BoxDirection(const Vector&in center, const Vector&in size, const Vector&in forward, 
          const Color&in color, int alpha = 0, float dur = 0.05f)
    {
        BoxDirection(center, size, forward, color[0], color[1], color[2], alpha, dur);
    }


    
    void Cross(const Vector&in pos, float size,
            const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Cross(pos, size, color[0], color[1], color[2], ignoreZ, dur);
    }

    // LATER CROSS 3D - 3DOriented
    void Cross3D(const Vector&in pos, float size,
               const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Cross3D(pos, size, color[0], color[1], color[2], ignoreZ, dur);
    }

    void Cross3D(const Vector&in pos, const Vector&in mins, const Vector&in maxs,
            const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Cross3D(pos, mins, maxs, color[0], color[1], color[2], ignoreZ, dur);
    }


    void Cross3DOriented(const Vector&in pos, const QAngle&in angles, float size,
               const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Cross3DOriented(pos, angles, size, color[0], color[1], color[2], ignoreZ, dur);
    }

    /* int c??? - What does that even Meeean???
    void Cross3DOriented(const matrix3x4_t&in m, float size,
            int c, bool ignoreZ = false, float dur = 0.05f)
    {
        Cross3DOriented(m, size, c, ignoreZ, dur);
    }*/

    void DrawTickMarkedLine(const Vector&in start, const Vector&in end, float tickDist, int tickTextDist, const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        DrawTickMarkedLine(start, end, tickDist, tickTextDist, color[0], color[1], color[2], ignoreZ, dur);
    }

    void EntityBounds(const CBaseEntity@ entity, const Color&in color, float dur = 0.05f)
    {
        EntityBounds(entity, color[0], color[1], color[2], color[3], dur);
    }

    void EntityText(int entityId, int offset, const string&in text, const Color&in color, float dur = 0.05f)
    {
        EntityText(entityId, offset, text, dur, color[0], color[1], color[2], color[3]);
    }

    void EntityTextAtPosition(const Vector&in origin, int offset, const string&in text, const Color&in color, float dur = 0.05f)
    {
        EntityTextAtPosition(origin, offset, text, dur, color[0], color[1], color[2], color[3]);
    }

    void HorzArrow(const Vector&in start, const Vector&in end, float width, const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        HorzArrow(start, end, width, color[0], color[1], color[2], color[3], ignoreZ, dur);
    }

    void VertArrow(const Vector&in start, const Vector&in end, float width, const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        VertArrow(start, end, width, color[0], color[1], color[2], color[3], ignoreZ, dur);
    }

    void YawArrow(const Vector&in start, float yaw, float length, float width, const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        YawArrow(start, yaw, length, width, color[0], color[1], color[2], color[3], ignoreZ, dur);
    }

    void ScreenText(float x, float y, const string&in text, const Color&in color, float dur = 0.05f)
    {
        ScreenText(x, y, text, color[0], color[1], color[2], color[3], dur);
    }

    void SweptBox(const Vector&in start, const Vector&in end, const Vector&in mins, const Vector&in maxs, const QAngle&in angles, const Color&in color, float dur = 0.05f)
    {
        SweptBox(start, end, mins, maxs, angles, color[0], color[1], color[2], color[3], dur);
    }

    void SweptBox(const Vector&in start, const Vector&in end, Vector size, const QAngle&in angles, const Color&in color, float dur = 0.05f)
    {
        Vector mins = size * -0.5f;
        Vector maxs = size * 0.5f;
        SweptBox(start, end, mins, maxs, angles, color[0], color[1], color[2], color[3], dur);
    }

    void Triangle(const Vector&in p1, const Vector&in p2, const Vector&in p3, const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        Triangle(p1, p2, p3, color[0], color[1], color[2], color[3], ignoreZ, dur);
    }

    void PlaneSolid(const Vector&in origin, const Vector&in normal, 
                float size = 100.0f,
                int r = 255, int g = 100, int b = 100, int a = 80, 
                bool ignoreZ = false, float dur = 0.05f)
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

        
        Triangle(p1, p2, p3, r, g, b, a, ignoreZ, dur);
        Triangle(p1, p3, p4, r, g, b, a, ignoreZ, dur);
        
    }

    void PlaneSolid(const Vector&in origin, const Vector&in normal, 
            float size = 100.0f,
            Color color = Color(255, 100, 100, 80),
            bool ignoreZ = false, float dur = 0.05f)
    {
        PlaneSolid(origin, normal, size, color[0], color[1], color[2], color[3], ignoreZ, dur);
    }

    void PlaneWire(const Vector&in origin, const Vector&in normal, 
               float size = 100.0f, int divisions = 4,
               int r = 255, int g = 255, int b = 100, 
               bool ignoreZ = false, float dur = 0.05f)
    {
        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);
        
        Vector right = normal.Cross(arb).Normalized() * (size * 0.5f);
        Vector up    = normal.Cross(right).Normalized() * (size * 0.5f);

        

        Line(origin + right + up, origin + right - up, r, g, b, ignoreZ, dur);
        Line(origin + right - up, origin - right - up, r, g, b, ignoreZ, dur);
        Line(origin - right - up, origin - right + up, r, g, b, ignoreZ, dur);
        Line(origin - right + up, origin + right + up, r, g, b, ignoreZ, dur);

        if (divisions > 1)
        {
            float step = 1.0f / divisions;
            for (int i = 1; i < divisions; i++)
            {
                float t = step * i - 0.5f;
                
                // Horizontal Lines
                Line(origin + right + up + (up * -2.0f * t), 
                    origin - right + up + (up * -2.0f * t), r, g, b, ignoreZ, dur);
                
                // Vertical Lines
                Line(origin + right + up + (right * -2.0f * t), 
                    origin + right - up + (right * -2.0f * t), r, g, b, ignoreZ, dur);
            }
        }

        
    }

    void Plane(const Vector&in origin, const Vector&in normal, float size = 100.0f,
           int r = 255, int g = 100, int b = 100, int a = 255, bool ignoreZ = false, float dur = 0.05f)
    {
        PlaneWire(origin, normal, size, 4, r, g, b, ignoreZ, dur);
        PlaneSolid(origin, normal, size, r, g, b, a, ignoreZ, dur);
    }


    void Disk(const Vector&in origin, const Vector&in normal, float radius,
          int r, int g, int b, int alpha = 255, bool ignoreZ = false, bool circle = false, float dur = 0.05f, float segments = 16)
    {
        if (radius <= 0.001f || segments < 3) return;

        Vector arb = Vector(0, 0, 1);
        if (fabs(normal.z) > 0.98f)
            arb = Vector(1, 0, 0);

        Vector right = normal.Cross(arb).Normalized();
        Vector up    = normal.Cross(right).Normalized();

        float step = 6.283185f / segments;

        

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
                Line(v1, v2, r, g, b, ignoreZ, dur); 
            }

            if (alpha <= 0)
            {
                // Wireframe
                Line(origin, v1, r, g, b, ignoreZ, dur);
                Line(origin, v2, r, g, b, ignoreZ, dur);
            }
            else
            {
                // Solid
                TriangleInv(origin, v1, v2, r, g, b, alpha, ignoreZ, dur);
                
            }
        }

        
    }

    void Disk(const Vector&in origin, const Vector&in normal, float radius,
            const Color&in color, int alpha = 255, bool ignoreZ = false, bool circle = false, float dur = 0.05f, float segments = 16)
    {
        Disk(origin, normal, radius, color[0], color[1], color[2], alpha, ignoreZ, circle, dur, segments);
    }




    // ==============================================
    //
    //  ARROWS
    //
    // ==============================================




    // ----------------------------------------------
    //  New Arrow
    // ------------------------------

    void Arrow(const Vector&in from, const Vector&in to,
               int r, int g, int b, bool ignoreZ = false, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Line(from, to, r, g, b, ignoreZ, dur);
        Vector dir = (to - from).Normalized();
        Internal::_ArrowHeadCone(to, dir, headSize, headSize * 0.6f, r, g, b, 0, ignoreZ, dur, segments);
    }

    void Arrow(const Vector&in from, const Vector&in to,
               const Color&in color, bool ignoreZ = false, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Arrow(from, to, color[0], color[1], color[2], ignoreZ, dur, headSize, segments);
    }

    void DoubleArrow(const Vector&in from, const Vector&in to,
                     int r, int g, int b, bool ignoreZ = false, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        Line(from, to, r, g, b, ignoreZ, dur);
        
        Vector dir = (to - from).Normalized();
        Internal::_ArrowHeadCone(to, dir, headSize, headSize * 0.6f, r, g, b, 0, ignoreZ, dur, segments);
        Internal::_ArrowHeadCone(from, -dir, headSize, headSize * 0.6f, r, g, b, 0, ignoreZ, dur, segments);
    }

    void DoubleArrow(const Vector&in from, const Vector&in to,
                     const Color&in color, bool ignoreZ = false, float dur = 0.05f, float headSize = 8.0f, float segments = 12)
    {
        DoubleArrow(from, to, color[0], color[1], color[2], ignoreZ, dur, headSize, segments);
    }


    // ------------------------------
    //  Old Arrow
    // ------------------------------
    
    void ArrowOld(const Vector&in from, const Vector&in to,
               int r, int g, int b, bool ignoreZ = false, float dur = 0.05f)
    {
        Line(from, to, r, g, b, ignoreZ, dur);
        Cross(to, 3.0f, r, g, b, ignoreZ, dur);
    }

    void ArrowOld(const Vector&in from, const Vector&in to,
               const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        ArrowOld(from, to, color[0], color[1], color[2], ignoreZ, dur);
    }
    
    void DoubleArrowOld(const Vector&in from, const Vector&in to,
                     int r, int g, int b, bool ignoreZ = false, float dur = 0.05f)
    {
        Line(from, to, r, g, b, ignoreZ, dur);
        Cross(from, 3.5f, r, g, b, ignoreZ, dur);
        Cross(to,   3.5f, r, g, b, ignoreZ, dur);
    }

    void DoubleArrowOld(const Vector&in from, const Vector&in to,
                     const Color&in color, bool ignoreZ = false, float dur = 0.05f)
    {
        DoubleArrowOld(from, to, color[0], color[1], color[2], ignoreZ, dur);
    }



    // ==============================================
    //
    //  CYLINDER
    //
    // ==============================================
    

    void Cylinder(const Vector&in start, const Vector&in end, float radius,
                  int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
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
                    Line(prevS, s, r, g, b, ignoreZ, dur);   // start circle
                    Line(prevE, e, r, g, b, ignoreZ, dur);   // end circle
                    Line(s, e, r, g, b, ignoreZ, dur);       // side
                }
                else
                {
                    TriangleInv(prevS, s, e,   r, g, b, alpha, ignoreZ, dur);
                    TriangleInv(prevS, e, prevE, r, g, b, alpha, ignoreZ, dur);
                }
            }
            
            prevS = s;
            prevE = e;
            hasPrev = true;
        }
        
        
    }

    void Cylinder(const Vector&in start, const Vector&in end, float radius,
                  const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Cylinder(start, end, radius, color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }


    // ------------------------------
    //  Capped Cylinder (a cylinder with discs at each end)
    // ------------------------------

    void CappedCylinder(const Vector&in start, const Vector&in end, float radius,
                    int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {

        Cylinder(start, end, radius, r, g, b, alpha, ignoreZ, dur, segments);
        
        if (alpha <= 0)
        {
            Vector dir = (end - start).Normalized();
            // CHECK THIS LATER
            Disk(start, -dir, radius, r, g, b, 0, ignoreZ, false, dur, segments);
            Disk(end,    dir, radius, r, g, b, 0, ignoreZ, false, dur, segments);            
        }
        else
        {
            Vector dir = (end - start).Normalized();
            // CHECK THIS LATER
            Disk(start, -dir, radius, r, g, b, alpha, ignoreZ, false, dur, segments);
            Disk(end,    dir, radius, r, g, b, alpha, ignoreZ, false, dur, segments);
        }
        
    }

    void CappedCylinder(const Vector&in start, const Vector&in end, float radius,
                        const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        CappedCylinder(start, end, radius, color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }



    // ==============================================
    //
    //  SPHERE / HEMISPHERE
    //
    // ==============================================


    void Sphere(const Vector&in center, const QAngle&in angles, float radius, const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Sphere(center, angles, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }


    void Hemisphere(const Vector&in center, const Vector&in upDir, float radius,
                    int r, int g, int b, int alpha = 0, bool ignoreZ = false,
                    float dur = 0.05f, float segments = 16, float rings = 8)
    {
        Vector forward, right;
        VectorVectors(upDir.Normalized(), right, forward);

        float ringStep = 1.0f / rings;
        float angleStep = 6.283185f / segments;

        

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
                    Line(p1, p2, r,g,b,ignoreZ,dur);
                    Line(p2, p3, r,g,b,ignoreZ,dur);
                }
                else
                {
                    Triangle(p1, p2, p3, r,g,b,alpha, ignoreZ,dur);
                    Triangle(p1, p3, p4, r,g,b,alpha, ignoreZ,dur);
                }
            }
        }

        
    }

    void Hemisphere(const Vector&in center, const Vector&in upDir, float radius,
                    const Color&in color, int alpha = 0, bool ignoreZ = false,
                    float dur = 0.05f, float segments = 16, float rings = 8)
    {
       CapsuleHemi(center, upDir, radius, color[0], color[1], color[2], alpha, ignoreZ, dur, segments, rings);
    }


    // ------------------------------
    //  Capped Hemisphere (hemisphere + disk)
    // -------------------------------------

    void CappedHemisphere(const Vector&in center, const Vector&in upDir, float radius,
                        int r, int g, int b, int alpha = 0, bool ignoreZ = false,
                        float dur = 0.05f, float segments = 16, float rings = 8)
    {
        Vector dir = upDir.Normalized();

       CapsuleHemi(center, dir, radius, r, g, b, alpha, ignoreZ, dur, segments, rings);

        Vector baseCenter = center;  

        if (alpha <= 0)
        {
            // CHECK THIS LATER
            Disk(baseCenter, -dir, radius, r, g, b, 0, ignoreZ, false, dur, segments);
        }
        else
        {
            Disk(baseCenter, -dir, radius, r, g, b, alpha, ignoreZ, false, dur, segments);
        }
    }

    void CappedHemisphere(const Vector&in center, const Vector&in upDir, float radius,
                        const Color&in color, int alpha = 0, bool ignoreZ = false,
                        float dur = 0.05f, float segments = 16, float rings = 8)
    {
        CappedHemisphere(center, upDir, radius, color[0], color[1], color[2], alpha, ignoreZ, dur, segments, rings);
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
                 const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, bool wireframe = false)
    {
        Capsule(start, end, radius, color[0], color[1], color[2], alpha, dur, wireframe, ignoreZ);
    }


    // --------------------------------------------
    //  Capsule with different radii (trapezoidal)
    // ----------------------------------------------

    void Capsule(const Vector&in start, const Vector&in end,
                 float radiusStart, float radiusEnd,
                 int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
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
                    Line(prevS, s, r, g, b, ignoreZ, dur);
                    Line(prevE, e, r, g, b, ignoreZ, dur);
                }
                else
                {
                    Triangle(prevS, s, e, r, g, b, alpha, ignoreZ, dur);
                    Triangle(prevS, e, prevE, r, g, b, alpha, ignoreZ, dur);
                }
            }
            Line(s, e, r, g, b, ignoreZ, dur);  

            prevS = s;
            prevE = e;
            hasPrev = true;
        }

        Sphere(start, radiusStart, r, g, b, ignoreZ, dur);
        Sphere(end,   radiusEnd,   r, g, b, ignoreZ, dur);

        
    }

    void Capsule(const Vector&in start, const Vector&in end,
                 float radiusStart, float radiusEnd,
                 const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Capsule(start, end, radiusStart, radiusEnd,
                color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }




    // ==============================================
    //
    //  CapsuleHemi
    //
    // ==============================================


    void CapsuleHemi(const Vector&in start, const Vector&in end, float radius,
                     int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        if ((end - start).LengthSqr() < 0.0001f)
        {
            Sphere(start, radius, r, g, b, ignoreZ, dur);
            return;
        }


        Cylinder(start, end, radius, r, g, b, alpha, ignoreZ, dur, segments);


        Vector dir = (end - start).Normalized();

        Hemisphere(start, -dir, radius, r, g, b, alpha, ignoreZ, dur, segments, rings);
       CapsuleHemi(end,   dir,  radius, r, g, b, alpha, ignoreZ, dur, segments, rings);
    }

    void CapsuleHemi(const Vector&in start, const Vector&in end, float radius,
                     const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        CapsuleHemi(start, end, radius, color[0], color[1], color[2], alpha, ignoreZ, dur, segments, rings);
    }


    // ----------------------------------------------
    //  CapsuleHemi with different radii
    // ----------------------------------------------

    void CapsuleHemi(const Vector&in start, const Vector&in end,
                     float radiusStart, float radiusEnd,
                     int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        Vector dir = end - start;
        float len = dir.Length();
        if (len < 0.001f)
        {
            Sphere(start, radiusStart, r, g, b, ignoreZ, dur);
            return;
        }
        dir /= len;

        Capsule(start, end, radiusStart, radiusEnd, r, g, b, alpha, ignoreZ, dur, segments);

        Hemisphere(start, -dir, radiusStart, r, g, b, alpha, ignoreZ, dur, segments, rings);
        Hemisphere(end,   dir,  radiusEnd,   r, g, b, alpha, ignoreZ, dur, segments, rings);
    }

    void CapsuleHemi(const Vector&in start, const Vector&in end,
                     float radiusStart, float radiusEnd,
                     const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, 
                     float segments = 16, float rings = 6)
    {
        CapsuleHemi(start, end, radiusStart, radiusEnd,
                    color[0], color[1], color[2], alpha, ignoreZ, dur, segments, rings);
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
                       int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
         

        // Near plane
        if (alpha <= 0)
        {
            Line(ntl, ntr, r, g, b, ignoreZ, dur);
            Line(ntr, nbr, r, g, b, ignoreZ, dur);
            Line(nbr, nbl, r, g, b, ignoreZ, dur);
            Line(nbl, ntl, r, g, b, ignoreZ, dur);
        }
        else
        {
            Triangle(ntl, ntr, nbr, r, g, b, alpha, ignoreZ, dur);
            Triangle(ntl, nbr, nbl, r, g, b, alpha, ignoreZ, dur);
        }

        // Far plane
        if (alpha <= 0)
        {
            Line(ftl, ftr, r, g, b, ignoreZ, dur);
            Line(ftr, fbr, r, g, b, ignoreZ, dur);
            Line(fbr, fbl, r, g, b, ignoreZ, dur);
            Line(fbl, ftl, r, g, b, ignoreZ, dur);
        }
        else
        {
            TriangleInv(ftl, ftr, fbr, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(ftl, fbr, fbl, r, g, b, alpha, ignoreZ, dur);
        }

        // Side faces
        if (alpha <= 0)
        {
            Line(ntl, ftl, r, g, b, ignoreZ, dur);
            Line(ntr, ftr, r, g, b, ignoreZ, dur);
            Line(nbl, fbl, r, g, b, ignoreZ, dur);
            Line(nbr, fbr, r, g, b, ignoreZ, dur);
        }
        else
        {
            // Right
            TriangleInv(ntr, nbr, fbr, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(ntr, fbr, ftr, r, g, b, alpha, ignoreZ, dur);
            // Left
            Triangle(ntl, nbl, fbl, r, g, b, alpha, ignoreZ, dur);
            Triangle(ntl, fbl, ftl, r, g, b, alpha, ignoreZ, dur);
            // Top
            TriangleInv(ntl, ntr, ftr, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(ntl, ftr, ftl, r, g, b, alpha, ignoreZ, dur);
            // Bottom
            Triangle(nbl, nbr, fbr, r, g, b, alpha, ignoreZ, dur);
            Triangle(nbl, fbr, fbl, r, g, b, alpha, ignoreZ, dur);
        }

        
    }

    void SimpleFrustum(const Vector&in ntl, const Vector&in ntr,
                       const Vector&in nbl, const Vector&in nbr,
                       const Vector&in ftl, const Vector&in ftr,
                       const Vector&in fbl, const Vector&in fbr,
                       const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        SimpleFrustum(ntl, ntr, nbl, nbr, ftl, ftr, fbl, fbr,
                      color[0], color[1], color[2], alpha, ignoreZ, dur);
    }


    void Frustum(const Vector&in origin,
                 const QAngle&in angles,
                 float fov,                    
                 float aspectRatio,            
                 float nearDist,
                 float farDist,
                 const Vector&in farOffset,    
                 int r, int g, int b, int alpha = 0, bool ignoreZ = false,
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

        SimpleFrustum(ntl, ntr, nbl, nbr, ftl, ftr, fbl, fbr, r, g, b, alpha, ignoreZ, dur);
    }

    void Frustum(const Vector&in origin,
                 const QAngle&in angles,
                 float fov,
                 float aspectRatio,
                 float nearDist,
                 float farDist,
                 const Vector&in farOffset,
                 const Color&in color, int alpha = 0, bool ignoreZ = false,
                 float dur = 0.05f)
    {
        Frustum(origin, angles, fov, aspectRatio, nearDist, farDist, farOffset,
                color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Frustum(const Vector&in origin, const QAngle&in angles,
                 float fov = 90.0f, float aspectRatio = 16.0f/9.0f,
                 float nearDist = 10.0f, float farDist = 1000.0f,
                 int r = 100, int g = 180, int b = 255, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Frustum(origin, angles, fov, aspectRatio, nearDist, farDist, Vector(0,0,0), r, g, b, alpha, ignoreZ, dur);
    }




    // ==============================================
    //
    //  CONE
    //
    // ==============================================

    void Cone(const Vector&in eyePos, const Vector&in fwd, const Vector&in right, const Vector&in up,
              float near, float far, float halfAngleDeg,
              int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        // Frustum-style cone
        float rNear = tan(halfAngleDeg * DEG2RAD) * near;
        float rFar  = tan(halfAngleDeg * DEG2RAD) * far;
        float step = 6.283185f / segments;

         
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
                    Line(prevN, cn, r,g,b,ignoreZ,dur);
                    Line(prevF, cf, r,g,b,ignoreZ,dur);
                    Line(cn, cf, r,g,b,ignoreZ,dur);
                }
                else
                {
                    Triangle(prevN, cn, cf, r,g,b,alpha,ignoreZ,dur);
                    Triangle(prevN, cf, prevF, r,g,b,alpha,ignoreZ,dur);
                }
            }
            prevN = cn; prevF = cf; hasPrev = true;
        }
        
    }

    void Cone(const Vector&in eyePos, const Vector&in fwd, const Vector&in right, const Vector&in up,
              float near, float far, float halfAngleDeg,
              const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Cone(eyePos, fwd, right, up, near, far, halfAngleDeg, color[0],color[1],color[2], alpha, ignoreZ, dur, segments);
    }

    void Cone(const Vector&in eyePos, const QAngle&in angles,
          float nearDist, float farDist, float halfAngleDeg,
          int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Vector fwd, right, up;
        AngleVectors(angles, fwd, right, up);
        
        Cone(eyePos, fwd, right, up, nearDist, farDist, halfAngleDeg, r, g, b, alpha, ignoreZ, dur, segments);
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
                bool ignoreZ = false, float duration = 0.05f)
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

         

        Line(p1, p2, r, g, b, ignoreZ, duration);
        Line(p2, p3, r, g, b, ignoreZ, duration);
        Line(p3, p4, r, g, b, ignoreZ, duration);
        Line(p4, p1, r, g, b, ignoreZ, duration);

        Line(p5, p7, r, g, b, ignoreZ, duration);
        Line(p6, p7, r, g, b, ignoreZ, duration);
        Line(p5, p6, r, g, b, ignoreZ, duration);

        
    }


    void ThickArrow(const Vector&in start, const Vector&in end, float width,
                    int r, int g, int b, bool ignoreZ = false, float duration = 0.05f)
    {
        ThickArrow(start, end, width, 2.0f, r, g, b, ignoreZ, duration);
    }


    void ThickArrow(const Vector&in start, const Vector&in end, float width,
                    const Color&in color, bool ignoreZ = false, float duration = 0.05f)
    {
        ThickArrow(start, end, width, color[0], color[1], color[2], ignoreZ, duration);
    }

    void ThickArrow(const Vector&in start, const Vector&in end, 
                float width, float headSize,
                const Color&in color, bool ignoreZ = false, float duration = 0.05f)
    {
        ThickArrow(start, end, width, headSize, 
                color[0], color[1], color[2], ignoreZ, duration);
    }


    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                      float width = 8.0f,
                      float headSize = 2.0f,
                      int r = 255, int g = 255, int b = 255,
                      bool ignoreZ = false, float duration = 0.05f)
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

         

        Line(p1, p2, r, g, b, ignoreZ, duration);
        Line(p2, p3, r, g, b, ignoreZ, duration);
        Line(p3, p4, r, g, b, ignoreZ, duration);
        Line(p4, p1, r, g, b, ignoreZ, duration);

        Line(p5, p7, r, g, b, ignoreZ, duration);
        Line(p6, p7, r, g, b, ignoreZ, duration);
        Line(p5, p6, r, g, b, ignoreZ, duration);

        Line(p8, p10, r, g, b, ignoreZ, duration);
        Line(p9, p10, r, g, b, ignoreZ, duration);
        Line(p8, p9, r, g, b, ignoreZ, duration);

        
    }
    
    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width, float headSize,
                        const Color&in color, bool ignoreZ = false, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, headSize, 
                        color[0], color[1], color[2], ignoreZ, duration);
    }

    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width,
                        const Color&in color, bool ignoreZ = false, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, 2.0f, color, ignoreZ, duration);
    }


    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                      float width = 8.0f,
                      float headSizeStart = 2.0f,
                      float headSizeEnd   = 2.0f, 
                      int r = 255, int g = 255, int b = 255,
                      bool ignoreZ = false, float duration = 0.05f)
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
        float headLengthStart = Internal::_min(width * headSizeStart, maxHead);
        float headLengthEnd   = Internal::_min(width * headSizeEnd,   maxHead);

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

         

        Line(p1, p2, r, g, b, ignoreZ, duration);
        Line(p2, p3, r, g, b, ignoreZ, duration);
        Line(p3, p4, r, g, b, ignoreZ, duration);
        Line(p4, p1, r, g, b, ignoreZ, duration);

        Line(p5, p7, r, g, b, ignoreZ, duration);
        Line(p6, p7, r, g, b, ignoreZ, duration);
        Line(p5, p6, r, g, b, ignoreZ, duration);

        Line(p8, p10, r, g, b, ignoreZ, duration);
        Line(p9, p10, r, g, b, ignoreZ, duration);
        Line(p8, p9, r, g, b, ignoreZ, duration);

        
    }

    void DoubleThickArrow(const Vector&in start, const Vector&in end, 
                        float width, float headSizeStart, float headSizeEnd,
                        const Color&in color, bool ignoreZ = false, float duration = 0.05f)
    {
        DoubleThickArrow(start, end, width, headSizeStart, headSizeEnd,
                        color[0], color[1], color[2], ignoreZ, duration);
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
           bool ignoreZ = false,
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
                    Line(p1, p2, r, g, b, ignoreZ, dur);
                    Line(p2, p3, r, g, b, ignoreZ, dur);
                }
                else
                {
                    Triangle(p1, p2, p3, r, g, b, alpha, ignoreZ, dur);
                    Triangle(p1, p3, p4, r, g, b, alpha, ignoreZ, dur);
                }
            }
        }

        
    }

    void Torus(const Vector&in center, const Vector&in normal,
            float majorRadius, float minorRadius,
            const Color&in color, int alpha = 0, bool ignoreZ = false,
            float dur = 0.05f, float segments = 24, float sides = 12)
    {
        Torus(center, normal, majorRadius, minorRadius,
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments, sides);
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
           bool ignoreZ = false, float dur = 0.05f, float segments = 64)
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

         

        for (int i = 1; i <= segments; i++)
        {
            float angle = float(i) * step;
            float h = float(i) * heightStep;

            Vector offset = right * (cos(angle) * radius) + up * (sin(angle) * radius);
            Vector current = start + forward * h + offset;


            Line(prev, current, r, g, b, ignoreZ, dur);
            

            prev = current;
        }

        
    }

    void Helix(const Vector&in start, const Vector&in dir,
            float length, float radius, float turns,
            const Color&in color,
            bool ignoreZ = false, float dur = 0.05f, float segments = 64)
    {
        Helix(start, dir, length, radius, turns, color[0], color[1], color[2], ignoreZ, dur, segments);
    }




    // ==============================================
    //
    //  ANGLE
    //
    // ==============================================



    void Angle(const Vector&in center,
            const Vector&in normal,
            const Vector&in dir1,
            const Vector&in dir2,
            float radius,
            int r, int g, int b, int alpha = 0,
            bool ignoreZ = false,
            float dur = 0.05f, float segments = 24)
    {
        Vector n  = normal.Normalized();
        Vector d1 = dir1.Normalized();
        Vector d2 = dir2.Normalized();

        float angleDeg = Internal::SafeAcos(d1.Dot(d2)) * RAD2DEG;

        Arc(center, n, d1, radius, angleDeg, r, g, b, alpha, ignoreZ, dur, segments);
        Line(center, center + d1 * radius * 1.15f, r, g, b, ignoreZ, dur);
        Line(center, center + d2 * radius * 1.15f, r, g, b, ignoreZ, dur);
        Text(center + n * 2.0f + Vector(0, 0, 10), "Angle: " + angleDeg, ignoreZ, dur);
    }

    void Angle(const Vector&in center,
            const Vector&in normal,
            const Vector&in dir1,
            const Vector&in dir2,
            float radius,
            const Color&in color, int alpha = 0,
            bool ignoreZ = false,
            float dur = 0.05f, float segments = 24)
    {
        Angle(center, normal, dir1, dir2, radius,
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }

    void Angle(const Vector&in center,
            const Vector&in point1,
            const Vector&in point2,
            float radius = 20.0f,
            int r = 255, int g = 200, int b = 100, int alpha = 0,
            bool ignoreZ = false, float dur = 0.1f, float segments = 24)
    {
        Vector d1 = (point1 - center).Normalized();
        Vector d2 = (point2 - center).Normalized();

        Vector normal = d1.Cross(d2);
        normal = (normal.Length() < 0.001f) ? Vector(0, 0, 1) : normal.Normalized();

        float angleDeg = Internal::SafeAcos(d1.Dot(d2)) * RAD2DEG;

        Arc(center, normal, d1, radius, angleDeg, r, g, b, alpha, ignoreZ, dur, segments);
        Line(center, center + d1 * radius * 1.2f, r, g, b, ignoreZ, dur);
        Line(center, center + d2 * radius * 1.2f, r, g, b, ignoreZ, dur);
        Text(center + normal * (radius * 0.6f), "Angle: " + angleDeg, ignoreZ, dur);
    }

    void Angle(const Vector&in center,
            const Vector&in point1,
            const Vector&in point2,
            const Color&in color,
            float radius = 20.0f,
            bool ignoreZ = false, int alpha = 0,
            float dur = 0.1f, float segments = 24)
    {
        Angle(center, point1, point2, radius,
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }




    // ==============================================
    //
    //  PYRAMID / TETRAHEDRON
    //
    // ==============================================


    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                float rotDeg,
                int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
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

         

        if (alpha <= 0)
        {
            Line(b0, b1, r, g, b, ignoreZ, dur);
            Line(b1, b2, r, g, b, ignoreZ, dur);
            Line(b2, b3, r, g, b, ignoreZ, dur);
            Line(b3, b0, r, g, b, ignoreZ, dur);

            Line(b0, apex, r, g, b, ignoreZ, dur);
            Line(b1, apex, r, g, b, ignoreZ, dur);
            Line(b2, apex, r, g, b, ignoreZ, dur);
            Line(b3, apex, r, g, b, ignoreZ, dur);
        }
        else
        {
            TriangleInv(b0, b1, b2, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(b0, b2, b3, r, g, b, alpha, ignoreZ, dur);

            Triangle(b0, b1, apex, r, g, b, alpha, ignoreZ, dur);
            Triangle(b1, b2, apex, r, g, b, alpha, ignoreZ, dur);
            Triangle(b2, b3, apex, r, g, b, alpha, ignoreZ, dur);
            Triangle(b3, b0, apex, r, g, b, alpha, ignoreZ, dur);
        }

        
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                float rotDeg,
                const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, rotDeg, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, 0.0f, r, g, b, alpha, ignoreZ, dur);
    }

    void Pyramid(const Vector&in origin, const Vector&in dir,
                const Vector&in size,
                const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Pyramid(origin, dir, size, 0.0f, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }


    void Tetrahedron(const Vector&in center, const Vector&in dir,
                    float radius,
                    int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
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

         

        if (alpha <= 0)
        {
            Line(v0, v1,   r, g, b, ignoreZ, dur);
            Line(v1, v2,   r, g, b, ignoreZ, dur);
            Line(v2, v0,   r, g, b, ignoreZ, dur);

            Line(v0, apex, r, g, b, ignoreZ, dur);
            Line(v1, apex, r, g, b, ignoreZ, dur);
            Line(v2, apex, r, g, b, ignoreZ, dur);
        }
        else
        {
            TriangleInv(v0, v1, v2, r, g, b, alpha, ignoreZ, dur);

            Triangle(v0, v1, apex, r, g, b, alpha, ignoreZ, dur);
            Triangle(v1, v2, apex, r, g, b, alpha, ignoreZ, dur);
            Triangle(v2, v0, apex, r, g, b, alpha, ignoreZ, dur);
        }

        
    }

    void Tetrahedron(const Vector&in center, const Vector&in dir,
                    float radius,
                    const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Tetrahedron(center, dir, radius, color[0], color[1], color[2], alpha, ignoreZ, dur);
    }




    // ==============================================
    //
    //  PRISM / TUBE
    //
    // ==============================================


    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            float rotDeg,
            int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
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

         

        if (alpha <= 0)
        {
            Line(s0, s1, r, g, b, ignoreZ, dur);
            Line(s1, s2, r, g, b, ignoreZ, dur);
            Line(s2, s0, r, g, b, ignoreZ, dur);

            Line(e0, e1, r, g, b, ignoreZ, dur);
            Line(e1, e2, r, g, b, ignoreZ, dur);
            Line(e2, e0, r, g, b, ignoreZ, dur);

            Line(s0, e0, r, g, b, ignoreZ, dur);
            Line(s1, e1, r, g, b, ignoreZ, dur);
            Line(s2, e2, r, g, b, ignoreZ, dur);
        }
        else
        {
            TriangleInv(s0, s1, s2, r, g, b, alpha, ignoreZ, dur);

            Triangle(e0, e1, e2, r, g, b, alpha, ignoreZ, dur);

            TriangleInv(s0, s1, e1, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(s0, e1, e0, r, g, b, alpha, ignoreZ, dur);

            Triangle(s1, s2, e2, r, g, b, alpha, ignoreZ, dur);
            Triangle(s1, e2, e1, r, g, b, alpha, ignoreZ, dur);

            TriangleInv(s2, s0, e0, r, g, b, alpha, ignoreZ, dur);
            TriangleInv(s2, e0, e2, r, g, b, alpha, ignoreZ, dur);
        }

        
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            float rotDeg,
            const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, rotDeg,
            color[0], color[1], color[2], alpha, ignoreZ, dur);
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            int r, int g, int b, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, 0.0f, r, g, b, alpha, ignoreZ, dur);
    }

    void Prism(const Vector&in origin, const Vector&in dir,
            float length, const Vector&in size,
            const Color&in color, int alpha = 0, bool ignoreZ = false, float dur = 0.05f)
    {
        Prism(origin, dir, length, size, 0.0f,
            color[0], color[1], color[2], alpha, ignoreZ, dur);
    }


    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float innerRadius,
            int r, int g, int b, int alpha = 0,
            bool ignoreZ = false, float dur = 0.05f, float segments = 16)
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
                    Line(prevSO, sO, r, g, b, ignoreZ, dur);
                    Line(prevEO, eO, r, g, b, ignoreZ, dur);
                    Line(sO, eO,    r, g, b, ignoreZ, dur);

                    Line(prevSI, sI, r, g, b, ignoreZ, dur);
                    Line(prevEI, eI, r, g, b, ignoreZ, dur);
                    Line(sI, eI,    r, g, b, ignoreZ, dur);

                    Line(prevSO, prevSI, r, g, b, ignoreZ, dur);
                    Line(prevEO, prevEI, r, g, b, ignoreZ, dur);
                }
                else
                {
                    TriangleInv(prevSO, sO, eO,    r, g, b, alpha, ignoreZ, dur);
                    TriangleInv(prevSO, eO, prevEO, r, g, b, alpha, ignoreZ, dur);

                    Triangle(prevSI, sI, eI,    r, g, b, alpha, ignoreZ, dur);
                    Triangle(prevSI, eI, prevEI, r, g, b, alpha, ignoreZ, dur);

                    TriangleInv(prevSO, sO, sI,    r, g, b, alpha, ignoreZ, dur);
                    TriangleInv(prevSO, sI, prevSI, r, g, b, alpha, ignoreZ, dur);

                    Triangle(prevEO, eO, eI,    r, g, b, alpha, ignoreZ, dur);
                    Triangle(prevEO, eI, prevEI, r, g, b, alpha, ignoreZ, dur);
                }
            }

            prevSO = sO; prevEO = eO;
            prevSI = sI; prevEI = eI;
            hasPrev = true;
        }

        
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float innerRadius,
            const Color&in color, int alpha = 0,
            bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Tube(start, end, outerRadius, innerRadius,
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float wallThickness,
            bool useThickness,
            int r, int g, int b, int alpha = 0,
            bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        float inner = useThickness
            ? Internal::_max(0.0f, outerRadius - wallThickness)
            : wallThickness;

        Tube(start, end, outerRadius, inner, r, g, b, alpha, ignoreZ, dur, segments);
    }

    void Tube(const Vector&in start, const Vector&in end,
            float outerRadius, float wallThickness,
            bool useThickness,
            const Color&in color, int alpha = 0,
            bool ignoreZ = false, float dur = 0.05f, float segments = 16)
    {
        Tube(start, end, outerRadius, wallThickness, useThickness,
            color[0], color[1], color[2], alpha, ignoreZ, dur, segments);
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
                    bool ignoreZ = false, bool viewcheck = false,
                    float dur = 0.05f, float headSize = 6.0f)
    {
        float speed = velocity.Length();
        if (speed < 0.001f) return;

        Vector tip = origin + velocity * scale;

        Arrow(origin, tip, r, g, b, ignoreZ, dur, headSize);

        Text(tip + Vector(0, 0, 8), "v: " + Internal::_truncf(speed), viewcheck, dur);
    }

    void VelocityArrow(const Vector&in origin, const Vector&in velocity,
                    float scale,
                    const Color&in color,
                    bool ignoreZ = false, bool viewcheck = false,
                    float dur = 0.05f, float headSize = 6.0f)
    {
        VelocityArrow(origin, velocity, scale,
                    color[0], color[1], color[2], ignoreZ, viewcheck, dur, headSize);
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
                        bool ignoreZ = false, bool viewcheck = false,
                        float dur = 0.05f, float headSize = 6.0f)
    {
        float mag = acceleration.Length();
        if (mag < 0.001f) return;

        Vector tip = origin + acceleration * scale;

        Arrow(origin, tip, r, g, b, ignoreZ, dur, headSize);

        Text(tip + Vector(0, 0, 8), "a: " + Internal::_truncf(mag), viewcheck, dur);
    }

    void AccelerationArrow(const Vector&in origin, const Vector&in acceleration,
                        float scale,
                        const Color&in color,
                        bool ignoreZ = false, bool viewcheck = false,
                        float dur = 0.05f, float headSize = 6.0f)
    {
        AccelerationArrow(origin, acceleration, scale,
                        color[0], color[1], color[2], ignoreZ, viewcheck, dur, headSize);
    }


    // ----------------------------------------------
    //  VelocityAccelerationArrows
    //
    //  Plots both vectors together — velocity in green,
    //  acceleration in orange, plus the projection of the acceleration
    //  onto the velocity as a dotted Line
    // ----------------------------------------------

    void VelocityAccelerationArrows(const Vector&in origin,
                                    const Vector&in velocity,
                                    const Vector&in acceleration,
                                    float velScale = 1.0f,
                                    float accScale = 1.0f,
                                    bool ignoreZ = false,
                                    bool viewcheck = false,
                                    float dur = 0.05f)
    {
        float speed = velocity.Length();
        float accMag = acceleration.Length();

        VelocityArrow(origin, velocity, velScale,
                    DebugRendererColors::GREEN, ignoreZ, viewcheck, dur);

        AccelerationArrow(origin, acceleration, accScale,
                        DebugRendererColors::ORANGE, ignoreZ, viewcheck, dur);

        if (speed > 0.001f && accMag > 0.001f)
        {
            Vector velDir = velocity / speed;
            float  proj   = acceleration.Dot(velDir);
            Vector aTan   = velDir * proj;
            Vector aNorm  = acceleration - aTan;

            Vector tipTan  = origin + aTan  * accScale;
            Vector tipNorm = origin + aNorm * accScale;

            DrawDashedLine(origin, tipTan,
                            DebugRendererColors::YELLOW[0],
                            DebugRendererColors::YELLOW[1],
                            DebugRendererColors::YELLOW[2], 
                            ignoreZ,
                            dur);

            DrawDashedLine(origin, tipNorm,
                            DebugRendererColors::CYAN[0],
                            DebugRendererColors::CYAN[1],
                            DebugRendererColors::CYAN[2], 
                            ignoreZ,
                            dur);

            Text(tipTan  + Vector(0,0,8), "a_tan: "  + Internal::_truncf(proj), viewcheck,        dur);
            Text(tipNorm + Vector(0,0,8), "a_norm: " + Internal::_truncf(aNorm.Length()), viewcheck, dur);
        }

        Text(origin + Vector(0, 0, 20),
            "spd=" + Internal::_truncf(speed) + " acc=" + Internal::_truncf(accMag), viewcheck, dur);
    }


    // ----------------------------------------------
    //  Guidedebug::Line
    // ----------------------------------------------

    void DrawDashedLine(const Vector&in from, const Vector&in to,
                                int r, int g, int b, bool ignoreZ = false,
                                float dur = 0.05f, 
                                float dashLen = 6.0f, float gapLen = 4.0f)
    {
        Vector dir = to - from;
        float  total = dir.Length();
        if (total < 0.001f) return;
        dir /= total;

        float t = 0.0f;
        bool  drawing = true;

         

        while (t < total)
        {
            float segLen = drawing ? dashLen : gapLen;
            float tEnd   = Internal::_min(t + segLen, total);

            if (drawing)
                Line(from + dir * t, from + dir * tEnd, r, g, b, ignoreZ, dur);

            t       = tEnd;
            drawing = !drawing;
        }

        
    }

    void DrawDashedLine(const Vector&in from, const Vector&in to,
                        const Color&in color, bool ignoreZ = false,
                        float dur = 0.05f, 
                        float dashLen = 6.0f, float gapLen = 4.0f)
    {
        DrawDashedLine(from, to, color[0], color[1], color[2], ignoreZ, dur, dashLen, gapLen);
    }
}
