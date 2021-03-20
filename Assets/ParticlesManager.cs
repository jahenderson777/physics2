using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;


public class ParticlesManager : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader = default;
    [SerializeField] private ComputeShader triToVertComputeShader = default;
    [SerializeField] private Material material = default;
    [SerializeField] private int size = 64;

    public struct Particle
    {
        public Vector2 position;
        public Vector2 velocity;
    }
    private ComputeBuffer drawBuffer, particles, argsBuffer;

    int stride, warpCount, kernelIndex, kernelIndexTriToVert;

    Particle[] initBuffer;

    private const int WARP_SIZE = 1024, DRAW_STRIDE = sizeof(float) * 3, ARGS_STRIDE = sizeof(int) * 4;
    private bool initialized;

    void OnEnable()
    {
        if (initialized)
        {
            OnDisable();
        }
        initialized = true;

        warpCount = Mathf.CeilToInt((float)size / WARP_SIZE);
        stride = Marshal.SizeOf(typeof(Particle));
        particles = new ComputeBuffer(size, stride);
        initBuffer = new Particle[size];

        for (int i = 0; i < size; i++)
        {
            initBuffer[i] = new Particle();
            initBuffer[i].position = Random.insideUnitCircle * 10f;
            initBuffer[i].velocity = Vector2.zero;
        }
        kernelIndex = computeShader.FindKernel("Update");
        kernelIndexTriToVert = triToVertComputeShader.FindKernel("Main");

        particles.SetData(initBuffer);
        computeShader.SetBuffer(kernelIndex, "Particles", particles);
        
        drawBuffer = new ComputeBuffer(size * 3, DRAW_STRIDE, ComputeBufferType.Append);
        drawBuffer.SetCounterValue(0);
        material.SetBuffer("_DrawTriangles", drawBuffer);
        computeShader.SetBuffer(kernelIndex, "_DrawTriangles", drawBuffer);

        computeShader.SetInt("_NumSourceTriangles", size);

        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new int[] { 0, 1, 0, 0 });
        triToVertComputeShader.SetBuffer(kernelIndexTriToVert, "_IndirectArgsBuffer", argsBuffer);
    }

    void LateUpdate()
    {
        //float[] arr = new float[size * 3]; drawBuffer.GetData(arr);
        drawBuffer.SetCounterValue(0);

        if (Input.GetKeyDown(KeyCode.R))
        {
            particles.SetData(initBuffer);
        }
        computeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        computeShader.SetInt("shouldMove", Input.GetMouseButton(0) ? 1 : 0);
        var mousePosition = GetMousePosition();
        computeShader.SetFloats("mousePosition", mousePosition);
        computeShader.SetFloat("dt", Time.deltaTime);
        computeShader.Dispatch(kernelIndex, warpCount, 1, 1);

        ComputeBuffer.CopyCount(drawBuffer, argsBuffer, 0);
        triToVertComputeShader.Dispatch(kernelIndexTriToVert, 1, 1, 1);

        Bounds b = new Bounds(Vector3.zero, Vector3.one * 5000);
        Graphics.DrawProceduralIndirect(material, b, MeshTopology.Triangles, argsBuffer, 0, null, null, UnityEngine.Rendering.ShadowCastingMode.Off, false);
    }

    float[] GetMousePosition()
    {
        var mp = Input.mousePosition;
        Vector3 mp3 = new Vector3(mp.x, mp.y, 10.0f);
        var v = Camera.main.ScreenToWorldPoint(mp3);
        return new float[] { v.x, v.y };
    }

    private void OnDisable()
    { 
        if (initialized)
        {
            particles.Release();
            drawBuffer.Release();
            argsBuffer.Release();
        }
        initialized = false;
    }
}