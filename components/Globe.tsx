
import createGlobe from "cobe";
import React, { useCallback, useEffect, useRef, useState } from "react";

// Utility for class merging (simplified version of cn/clsx/tailwind-merge)
function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(' ');
}

// Default configuration, but markers will be overridden by props
const GLOBE_CONFIG: any = {
  width: 800,
  height: 800,
  onRender: () => {},
  devicePixelRatio: 2,
  phi: 0,
  theta: 0.3,
  dark: 0,
  diffuse: 0.4,
  mapSamples: 16000,
  mapBrightness: 1.2,
  baseColor: [1, 1, 1],
  markerColor: [244 / 255, 63 / 255, 94 / 255], // Primary Rose color #f43f5e
  glowColor: [1, 1, 1],
  markers: [],
};

interface GlobeProps {
  className?: string;
  markers?: { location: [number, number]; size: number }[];
}

export function Globe({ className, markers }: GlobeProps) {
  let phi = 0;
  let width = 0;
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const pointerInteracting = useRef<number | null>(null);
  const pointerInteractionMovement = useRef(0);
  const [r, setR] = useState(0);
  const [unavailable, setUnavailable] = useState(false);

  const updatePointerInteraction = (value: number | null) => {
    pointerInteracting.current = value;
    if (canvasRef.current) {
      canvasRef.current.style.cursor = value !== null ? "grabbing" : "grab";
    }
  };

  const updateMovement = (clientX: number) => {
    if (pointerInteracting.current !== null) {
      const delta = clientX - pointerInteracting.current;
      pointerInteractionMovement.current = delta;
      setR(delta / 200);
    }
  };

  const onRender = useCallback(
    (state: Record<string, any>) => {
      if (!pointerInteracting.current) phi += 0.005;
      state.phi = phi + r;
      state.width = width * 2;
      state.height = width * 2;
    },
    [r]
  );

  const onResize = () => {
    if (canvasRef.current) {
      width = canvasRef.current.offsetWidth;
    }
  };

  useEffect(() => {
    if (!canvasRef.current) return;
    window.addEventListener("resize", onResize);
    onResize();

    const config = {
      ...GLOBE_CONFIG,
      markers: markers || GLOBE_CONFIG.markers,
      width: width * 2,
      height: width * 2,
      onRender,
    };

    // cobe braucht WebGL. Ist der Kontext nicht verfuegbar (alte Geraete,
    // deaktiviertes WebGL, Headless-Browser), wirft createGlobe und riss frueher
    // die ganze Seite mit in einen weissen Bildschirm.
    const supportsWebGL = (() => {
      try {
        const probe = document.createElement("canvas");
        return !!(
          probe.getContext("webgl") || probe.getContext("experimental-webgl")
        );
      } catch {
        return false;
      }
    })();

    let globe: { destroy: () => void } | null = null;
    try {
      if (!supportsWebGL) throw new Error("WebGL context unavailable");
      globe = createGlobe(canvasRef.current, config);
    } catch (e) {
      console.warn("[Globe] WebGL nicht verfuegbar, Globus wird ausgeblendet:", e);
      setUnavailable(true);
      window.removeEventListener("resize", onResize);
      return () => {};
    }

    const fadeIn = setTimeout(() => {
      if (canvasRef.current) canvasRef.current.style.opacity = "1";
    });
    return () => {
      clearTimeout(fadeIn);
      window.removeEventListener("resize", onResize);
      globe?.destroy();
    };
  }, [markers]);

  if (unavailable) return null;

  return (
    <div
      className={cn(
        "absolute inset-0 mx-auto aspect-[1/1] w-full max-w-[600px]",
        className
      )}
    >
      <canvas
        className={cn(
          "size-full opacity-0 transition-opacity duration-500 [contain:layout_paint_size]"
        )}
        ref={canvasRef}
        onPointerDown={(e) =>
          updatePointerInteraction(
            e.clientX - pointerInteractionMovement.current
          )
        }
        onPointerUp={() => updatePointerInteraction(null)}
        onPointerOut={() => updatePointerInteraction(null)}
        onMouseMove={(e) => updateMovement(e.clientX)}
        onTouchMove={(e) =>
          e.touches[0] && updateMovement(e.touches[0].clientX)
        }
      />
    </div>
  );
}
