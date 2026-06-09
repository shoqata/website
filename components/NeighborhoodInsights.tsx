
import React, { useState } from "react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import * as RechartsPrimitive from "recharts";
import { UserProfile } from "../types";
import { motion, AnimatePresence } from "framer-motion";
import { useTranslation } from "../context/LanguageContext";

// --- UTILS ---
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// --- UI COMPONENTS (Inline for portability) ---

// Avatar Components
const Avatar = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full", className)} {...props} />
));
Avatar.displayName = "Avatar";

const AvatarImage = React.forwardRef<HTMLImageElement, React.ImgHTMLAttributes<HTMLImageElement>>(({ className, ...props }, ref) => (
  <img ref={ref} className={cn("aspect-square h-full w-full object-cover", className)} {...props} />
));
AvatarImage.displayName = "AvatarImage";

const AvatarFallback = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("flex h-full w-full items-center justify-center rounded-full bg-stone-100 text-stone-500 text-xs font-bold", className)} {...props} />
));
AvatarFallback.displayName = "AvatarFallback";

// Tooltip Components (Simplified implementation using Framer Motion)
const SimpleTooltip = ({ content, children }: { content: string, children?: React.ReactNode }) => {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <div className="relative flex items-center justify-center" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
            {children}
            <AnimatePresence>
                {isVisible && (
                    <motion.div 
                        initial={{ opacity: 0, y: 5, scale: 0.9 }} 
                        animate={{ opacity: 1, y: 0, scale: 1 }} 
                        exit={{ opacity: 0, scale: 0.9 }}
                        className="absolute bottom-full mb-2 px-3 py-1.5 bg-stone-900 text-white text-xs rounded-lg whitespace-nowrap z-50 shadow-xl font-bold"
                    >
                        {content}
                        <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-stone-900 rotate-45" />
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    )
}

// Card Components
const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("rounded-[2rem] border bg-white text-stone-950 shadow-sm", className)} {...props} />
));
Card.displayName = "Card";

const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
));
CardContent.displayName = "CardContent";

// --- AVATAR GROUP ---

interface AvatarGroupProps {
    members: UserProfile[];
}

export function AvatarGroupWithTooltips({ members }: AvatarGroupProps) {
  // Show max 5, then +X
  const displayMembers = members.slice(0, 5);
  const remainingCount = members.length - 5;

  return (
    <div className="bg-white flex items-center justify-center rounded-full border border-stone-100 p-1 shadow-sm w-fit">
        <div className="flex items-center relative">
          {displayMembers.map((member, index) => (
            <div key={member.id} className={cn("relative hover:z-10 transition-all", index > 0 && "-ml-3")}>
                <SimpleTooltip content={member.displayName || 'Member'}>
                  <Avatar className="transition-all duration-300 hover:scale-110 hover:-translate-y-1 hover:shadow-lg border-2 border-white h-10 w-10 md:h-12 md:w-12 ring-1 ring-stone-100">
                    {member.photoFileName ? (
                        <AvatarImage src={member.photoFileName} alt={member.displayName} />
                    ) : (
                        <AvatarFallback>{member.displayName?.charAt(0)}</AvatarFallback>
                    )}
                  </Avatar>
                </SimpleTooltip>
            </div>
          ))}
          {remainingCount > 0 && (
             <div className="relative -ml-3 z-0">
                 <div className="h-10 w-10 md:h-12 md:w-12 rounded-full bg-stone-100 border-2 border-white flex items-center justify-center text-xs font-bold text-stone-500 ring-1 ring-stone-100">
                     +{remainingCount}
                 </div>
             </div>
          )}
        </div>
    </div>
  );
}

// --- CHART COMPONENTS ---

// Chart related components and types
const THEMES = { light: "", dark: ".dark" } as const;

export type ChartConfig = {
  [k in string]: {
    label?: React.ReactNode;
    icon?: React.ComponentType;
  } & (
    | { color?: string; theme?: never }
    | { color?: never; theme: Record<keyof typeof THEMES, string> }
  );
};

type ChartContextProps = {
  config: ChartConfig;
};

const ChartContext = React.createContext<ChartContextProps | null>(null);

const ChartStyle = ({ id, config }: { id: string; config: ChartConfig }) => {
  const colorConfig = Object.entries(config).filter(
    ([, config]) => config.theme || config.color
  );

  if (!colorConfig.length) {
    return null;
  }

  return (
    <style
      dangerouslySetInnerHTML={{
        __html: Object.entries(THEMES)
          .map(
            ([theme, prefix]) => `
${prefix} [data-chart=${id}] {
${colorConfig
  .map(([key, itemConfig]) => {
    const color =
      itemConfig.theme?.[theme as keyof typeof itemConfig.theme] ||
      itemConfig.color;
    return color ? `  --color-${key}: ${color};` : null;
  })
  .join("\n")}
}
`
          )
          .join("\n"),
      }}
    />
  );
};

function ChartContainer({
  id,
  className,
  children,
  config,
  ...props
}: React.ComponentProps<"div"> & {
  config: ChartConfig;
  children: React.ComponentProps<
    typeof RechartsPrimitive.ResponsiveContainer
  >["children"];
}) {
  const uniqueId = React.useId();
  const chartId = `chart-${id || uniqueId.replace(/:/g, "")}`;

  return (
    <ChartContext.Provider value={{ config }}>
      <div
        data-slot="chart"
        data-chart={chartId}
        className={cn(
          "[&_.recharts-cartesian-axis-tick_text]:fill-muted-foreground [&_.recharts-cartesian-grid_line[stroke='#ccc']]:stroke-border/50 [&_.recharts-curve.recharts-tooltip-cursor]:stroke-border [&_.recharts-polar-grid_[stroke='#ccc']]:stroke-border [&_.recharts-radial-bar-background-sector]:fill-muted [&_.recharts-rectangle.recharts-tooltip-cursor]:fill-muted [&_.recharts-reference-line_[stroke='#ccc']]:stroke-border flex aspect-video justify-center text-xs [&_.recharts-dot[stroke='#fff']]:stroke-transparent [&_.recharts-layer]:outline-hidden [&_.recharts-sector]:outline-hidden [&_.recharts-sector[stroke='#fff']]:stroke-transparent [&_.recharts-surface]:outline-hidden",
          className
        )}
        {...props}
      >
        <ChartStyle id={chartId} config={config} />
        <RechartsPrimitive.ResponsiveContainer>
          {children}
        </RechartsPrimitive.ResponsiveContainer>
      </div>
    </ChartContext.Provider>
  );
}

// Stats Chart Component for Neighborhood
interface StatsChartProps {
    members: UserProfile[];
}

export function NeighborhoodPaymentStats({ members }: StatsChartProps) {
  const { t } = useTranslation();
  // Calculate real stats
  const total = members.length;
  const paid = members.filter(m => m.membershipStatus === 'ACTIVE').length;
  const percentage = total > 0 ? Math.round((paid / total) * 100) : 0;
  
  // Simulate trend data based on the real current percentage
  // We create a curve that ends at the current percentage
  const chartData = [
    { date: "W1", value: Math.max(0, percentage - 15) },
    { date: "W2", value: Math.max(0, percentage - 8) },
    { date: "W3", value: Math.max(0, percentage - 12) },
    { date: "W4", value: Math.max(0, percentage - 5) },
    { date: "Current", value: percentage },
  ];

  const config = {
    value: {
      label: t('dash.insights.participation'),
      color: "hsl(142.1 76.2% 36.3%)", // Green
    },
  };

  const gradientId = "gradient-participation";
  const color = percentage >= 80 ? "hsl(142.1 76.2% 36.3%)" : percentage >= 50 ? "hsl(45 93% 47%)" : "hsl(0 72.2% 50.6%)";

  return (
    <Card className="p-0 border border-stone-100 shadow-sm overflow-hidden h-full">
      <CardContent className="p-6 pb-0 flex flex-col h-full justify-between">
        <div>
          <div className="text-sm font-bold text-stone-500 uppercase tracking-widest mb-1">
            {t('dash.insights.participation')}
          </div>
          <div className="flex items-baseline justify-between">
            <div className={cn(
                "text-3xl font-display font-bold",
                percentage >= 80 ? "text-green-600" : percentage >= 50 ? "text-amber-600" : "text-rose-600"
            )}>
              {percentage}%
            </div>
            <div className="flex items-center space-x-1 text-sm text-stone-400 font-medium">
              <span>{t('dash.insights.of')} {total} {t('dash.insights.members')}</span>
            </div>
          </div>
          <p className="text-xs text-stone-400 mt-2">{t('dash.insights.desc')}</p>
        </div>

        <div className="mt-4 h-24 overflow-hidden -mx-6 -mb-1">
          <ChartContainer
            config={config}
            className="w-full h-full"
          >
            <RechartsPrimitive.AreaChart data={chartData}>
              <defs>
                <linearGradient
                  id={gradientId}
                  x1="0"
                  y1="0"
                  x2="0"
                  y2="1"
                >
                  <stop
                    offset="5%"
                    stopColor={color}
                    stopOpacity={0.3}
                  />
                  <stop
                    offset="95%"
                    stopColor={color}
                    stopOpacity={0}
                  />
                </linearGradient>
              </defs>
              <RechartsPrimitive.XAxis dataKey="date" hide={true} />
              <RechartsPrimitive.Area
                dataKey="value"
                stroke={color}
                fill={`url(#${gradientId})`}
                fillOpacity={0.4}
                strokeWidth={3}
                type="monotone"
                animationDuration={1500}
              />
            </RechartsPrimitive.AreaChart>
          </ChartContainer>
        </div>
      </CardContent>
    </Card>
  );
}
