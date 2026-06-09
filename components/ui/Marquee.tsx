import React, { ComponentPropsWithoutRef, useRef } from 'react';

// Utility helper instead of importing from @/lib/utils
function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(' ');
}

interface MarqueeProps extends ComponentPropsWithoutRef<'div'> {
  className?: string;
  reverse?: boolean;
  pauseOnHover?: boolean;
  children?: React.ReactNode;
  vertical?: boolean;
  repeat?: number;
  autoFill?: boolean; // Note: simplified implementation ignores autoFill logic for now to keep it dependency-free, relying on 'repeat'
}

export function Marquee({
  className,
  reverse = false,
  pauseOnHover = false,
  children,
  vertical = false,
  repeat = 4,
  ...props
}: MarqueeProps) {
  return (
    <>
      <style>
        {`
          @keyframes marquee {
            from { transform: translateX(0); }
            to { transform: translateX(calc(-100% - var(--gap))); }
          }
          @keyframes marquee-vertical {
            from { transform: translateY(0); }
            to { transform: translateY(calc(-100% - var(--gap))); }
          }
          .animate-marquee {
            animation: marquee var(--duration) linear infinite;
          }
          .animate-marquee-vertical {
            animation: marquee-vertical var(--duration) linear infinite;
          }
        `}
      </style>
      <div
        {...props}
        className={cn(
          'group flex overflow-hidden p-2 [--duration:40s] [--gap:1rem] [gap:var(--gap)]',
          vertical ? 'flex-col' : 'flex-row',
          className
        )}
      >
        {Array.from({ length: repeat }).map((_, i) => (
          <div
            key={i}
            className={cn(
              'flex shrink-0 justify-around [gap:var(--gap)]',
              vertical ? 'animate-marquee-vertical flex-col' : 'animate-marquee flex-row',
              pauseOnHover && 'group-hover:[animation-play-state:paused]',
              reverse && '[animation-direction:reverse]'
            )}
          >
            {children}
          </div>
        ))}
      </div>
    </>
  );
}