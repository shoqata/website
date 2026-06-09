
import React, { useRef, useState } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Sphere, MeshDistortMaterial, Float, Text } from '@react-three/drei';
import * as THREE from 'three';

// Fix: Alias Three.js intrinsic elements to avoid JSX type errors in environments where JSX.IntrinsicElements is not properly augmented
const Group = 'group' as any;
const Mesh = 'mesh' as any;
const SphereGeometry = 'sphereGeometry' as any;
const MeshStandardMaterial = 'meshStandardMaterial' as any;
const AmbientLight = 'ambientLight' as any;
const PointLight = 'pointLight' as any;
const SpotLight = 'spotLight' as any;

const LocationPin = ({ position, label }: { position: [number, number, number], label: string }) => {
  const [hovered, setHovered] = useState(false);
  
  return (
    <Group position={position}>
      <Float speed={2} rotationIntensity={0.5} floatIntensity={0.5}>
        <Mesh 
          onPointerOver={() => setHovered(true)} 
          onPointerOut={() => setHovered(false)}
        >
          <SphereGeometry args={[0.15, 32, 32]} />
          <MeshStandardMaterial color={hovered ? "#f43f5e" : "#fb7185"} emissive="#f43f5e" emissiveIntensity={hovered ? 2 : 0.5} />
        </Mesh>
      </Float>
      {hovered && (
        <Text
          position={[0, 0.4, 0]}
          fontSize={0.2}
          color="black"
          anchorX="center"
          anchorY="middle"
        >
          {label}
        </Text>
      )}
    </Group>
  );
};

const Globe = () => {
  const meshRef = useRef<THREE.Mesh>(null!);
  
  useFrame((state) => {
    meshRef.current.rotation.y += 0.002;
  });

  return (
    <Mesh ref={meshRef}>
      <SphereGeometry args={[2, 64, 64]} />
      <MeshStandardMaterial 
        color="#f8fafc" 
        wireframe 
        transparent 
        opacity={0.1} 
      />
      <Sphere args={[1.95, 64, 64]}>
        <MeshDistortMaterial
          color="#f1f5f9"
          speed={1}
          distort={0.2}
          radius={1}
        />
      </Sphere>
      
      {/* Standorte als Pins auf der Kugel (Beispiel-Koordinaten) */}
      <LocationPin position={[1.8, 0.5, 0.8]} label="Zürich" />
      <LocationPin position={[-1.5, 1.2, 0.5]} label="Koretin" />
      <LocationPin position={[0.5, -1.8, 0.2]} label="Geneva" />
      <LocationPin position={[-0.8, -0.5, 1.8]} label="New York" />
    </Mesh>
  );
};

const NeighborhoodMap3D: React.FC = () => {
  return (
    <div className="w-full h-[500px] bg-transparent cursor-grab active:cursor-grabbing">
      <Canvas camera={{ position: [0, 0, 6], fov: 45 }}>
        <AmbientLight intensity={0.5} />
        <PointLight position={[10, 10, 10]} intensity={1} />
        <SpotLight position={[-10, 10, 10]} angle={0.15} penumbra={1} />
        <Globe />
        <OrbitControls enableZoom={false} autoRotate autoRotateSpeed={0.5} />
      </Canvas>
    </div>
  );
};

export default NeighborhoodMap3D;
