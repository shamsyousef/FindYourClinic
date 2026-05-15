'use client';

import { useId, useRef, useState } from 'react';

// ─── Area Chart ────────────────────────────────────────────────────────────

export interface AreaChartPoint {
  label: string;
  value: number;
}

export function AreaChart({
  data,
  color = '#3b82f6',
  height = 200,
  valueFormatter,
  maxLabels = 8,
}: {
  data: AreaChartPoint[];
  color?: string;
  height?: number;
  valueFormatter?: (n: number) => string;
  maxLabels?: number;
}) {
  const gradId = useId();
  const svgRef = useRef<SVGSVGElement | null>(null);
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);

  const width = 600;
  const padX = 32;
  const padY = 24;
  const innerW = width - padX * 2;
  const innerH = height - padY * 2;

  if (data.length === 0) {
    return <EmptyChart height={height} />;
  }

  const max = Math.max(...data.map((d) => d.value), 1);
  const min = 0;
  const range = max - min || 1;

  const points = data.map((d, i) => {
    const x = padX + (data.length === 1 ? innerW / 2 : (i / (data.length - 1)) * innerW);
    const y = padY + innerH - ((d.value - min) / range) * innerH;
    return { x, y, ...d };
  });

  const linePath = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`)
    .join(' ');

  const areaPath = `${linePath} L ${points[points.length - 1].x} ${padY + innerH} L ${points[0].x} ${padY + innerH} Z`;

  const gridLines = [0, 0.25, 0.5, 0.75, 1].map((t) => padY + innerH * t);

  const labelStep = Math.max(1, Math.ceil(data.length / maxLabels));
  const lastIdx = data.length - 1;
  const showDot = (i: number) =>
    data.length <= 12 || i === 0 || i === lastIdx || i % labelStep === 0;
  const showLabel = (i: number) => {
    if (i === 0) return true;
    if (i === lastIdx) return true;
    if (i % labelStep === 0 && lastIdx - i >= Math.ceil(labelStep / 2)) return true;
    return false;
  };

  // Resolve mouse position to nearest data index in SVG user space
  const handleMove = (e: React.MouseEvent<SVGSVGElement>) => {
    const svg = svgRef.current;
    if (!svg) return;
    const rect = svg.getBoundingClientRect();
    const userX = ((e.clientX - rect.left) / rect.width) * width;

    let nearest = 0;
    let best = Infinity;
    for (let i = 0; i < points.length; i++) {
      const d = Math.abs(points[i].x - userX);
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    setHoverIdx(nearest);
  };

  const active = hoverIdx !== null ? points[hoverIdx] : null;

  // Tooltip placement in % of viewBox (so it tracks the SVG even when scaled)
  const tooltipLeft = active ? `${(active.x / width) * 100}%` : '0%';
  const tooltipTop = active ? `${(active.y / height) * 100}%` : '0%';

  return (
    <div className="relative w-full h-full">
      <svg
        ref={svgRef}
        viewBox={`0 0 ${width} ${height}`}
        className="w-full h-full"
        preserveAspectRatio="none"
        onMouseMove={handleMove}
        onMouseLeave={() => setHoverIdx(null)}
      >
        <defs>
          <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.4" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>

        {gridLines.map((y, i) => (
          <line
            key={i}
            x1={padX}
            y1={y}
            x2={width - padX}
            y2={y}
            stroke="#1f2937"
            strokeWidth="1"
            strokeDasharray="3 4"
          />
        ))}

        <path d={areaPath} fill={`url(#${gradId})`} />
        <path d={linePath} fill="none" stroke={color} strokeWidth="2.5" strokeLinejoin="round" />

        {active && (
          <line
            x1={active.x}
            y1={padY}
            x2={active.x}
            y2={padY + innerH}
            stroke={color}
            strokeOpacity="0.35"
            strokeWidth="1"
            strokeDasharray="3 3"
            pointerEvents="none"
          />
        )}

        {points.map((p, i) =>
          showDot(i) && hoverIdx !== i ? (
            <circle
              key={i}
              cx={p.x}
              cy={p.y}
              r="3.5"
              fill="#0a0a0a"
              stroke={color}
              strokeWidth="2"
              pointerEvents="none"
            />
          ) : null,
        )}

        {active && (
          <g pointerEvents="none">
            <circle cx={active.x} cy={active.y} r="9" fill={color} fillOpacity="0.18" />
            <circle cx={active.x} cy={active.y} r="5" fill="#0a0a0a" stroke={color} strokeWidth="2.5" />
          </g>
        )}

        {points.map((p, i) =>
          showLabel(i) ? (
            <text
              key={`lbl-${i}`}
              x={p.x}
              y={height - 6}
              textAnchor="middle"
              fill={hoverIdx === i ? '#e5e7eb' : '#6b7280'}
              fontSize="11"
            >
              {p.label}
            </text>
          ) : null,
        )}
      </svg>

      {active && (
        <div
          className="absolute z-10 pointer-events-none"
          style={{
            left: tooltipLeft,
            top: tooltipTop,
            transform: 'translate(-50%, calc(-100% - 14px))',
          }}
        >
          <div className="px-3 py-2 bg-gray-950/95 backdrop-blur-sm border border-gray-700 rounded-lg shadow-xl shadow-black/40 text-xs whitespace-nowrap">
            <p className="text-gray-400 mb-0.5">{active.label}</p>
            <p className="font-semibold text-white tabular-nums" style={{ color }}>
              {valueFormatter ? valueFormatter(active.value) : active.value}
            </p>
          </div>
          <div
            className="w-2 h-2 mx-auto -mt-1 rotate-45 border-r border-b border-gray-700"
            style={{ background: 'rgb(3 7 18 / 0.95)' }}
          />
        </div>
      )}
    </div>
  );
}

// ─── Time Range Toggle ─────────────────────────────────────────────────────

export type TimeRange = '7D' | '30D' | '6M' | '1Y';

export const TIME_RANGES: { key: TimeRange; label: string }[] = [
  { key: '7D', label: '7D' },
  { key: '30D', label: '30D' },
  { key: '6M', label: '6M' },
  { key: '1Y', label: '1Y' },
];

export function TimeRangeToggle({
  value,
  onChange,
}: {
  value: TimeRange;
  onChange: (r: TimeRange) => void;
}) {
  return (
    <div className="flex bg-gray-950/60 border border-gray-800 rounded-lg p-0.5">
      {TIME_RANGES.map((r) => (
        <button
          key={r.key}
          onClick={() => onChange(r.key)}
          className={`px-2.5 py-1 text-xs font-medium rounded-md transition-colors ${
            value === r.key
              ? 'bg-gray-800 text-white'
              : 'text-gray-500 hover:text-gray-300'
          }`}
        >
          {r.label}
        </button>
      ))}
    </div>
  );
}

// ─── Donut Chart ───────────────────────────────────────────────────────────

export interface DonutSlice {
  label: string;
  value: number;
  color: string;
}

export function DonutChart({
  data,
  size = 180,
  thickness = 28,
  centerLabel,
  centerValue,
}: {
  data: DonutSlice[];
  size?: number;
  thickness?: number;
  centerLabel?: string;
  centerValue?: string | number;
}) {
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);
  const total = data.reduce((s, d) => s + d.value, 0);
  const radius = size / 2;
  const inner = radius - thickness;

  if (total === 0) {
    return (
      <div className="flex items-center justify-center text-gray-600 text-sm" style={{ height: size }}>
        No data
      </div>
    );
  }

  let cumulative = 0;
  const slices = data.map((d, i) => {
    const start = (cumulative / total) * Math.PI * 2 - Math.PI / 2;
    cumulative += d.value;
    const end = (cumulative / total) * Math.PI * 2 - Math.PI / 2;
    const largeArc = end - start > Math.PI ? 1 : 0;
    const mid = (start + end) / 2;
    const hovered = hoverIdx === i;

    // Slight outward shift when hovered
    const shift = hovered ? 6 : 0;
    const cx = radius + Math.cos(mid) * shift;
    const cy = radius + Math.sin(mid) * shift;

    const x1 = cx + radius * Math.cos(start);
    const y1 = cy + radius * Math.sin(start);
    const x2 = cx + radius * Math.cos(end);
    const y2 = cy + radius * Math.sin(end);
    const x3 = cx + inner * Math.cos(end);
    const y3 = cy + inner * Math.sin(end);
    const x4 = cx + inner * Math.cos(start);
    const y4 = cy + inner * Math.sin(start);

    const path = [
      `M ${x1} ${y1}`,
      `A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}`,
      `L ${x3} ${y3}`,
      `A ${inner} ${inner} 0 ${largeArc} 0 ${x4} ${y4}`,
      'Z',
    ].join(' ');

    return { ...d, path, percent: (d.value / total) * 100, hovered };
  });

  const active = hoverIdx !== null ? slices[hoverIdx] : null;

  return (
    <div className="flex flex-col items-center gap-5">
      <div className="relative" style={{ width: size, height: size }}>
        <svg
          viewBox={`0 0 ${size} ${size}`}
          className="w-full h-full overflow-visible"
          onMouseLeave={() => setHoverIdx(null)}
        >
          {slices.map((s, i) => (
            <path
              key={i}
              d={s.path}
              fill={s.color}
              opacity={hoverIdx === null || hoverIdx === i ? 1 : 0.35}
              style={{ transition: 'opacity 150ms, d 200ms', cursor: 'pointer' }}
              onMouseEnter={() => setHoverIdx(i)}
            >
              <title>{s.label}: {s.value} ({s.percent.toFixed(1)}%)</title>
            </path>
          ))}
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
          {active ? (
            <>
              <span className="text-2xl font-bold tabular-nums" style={{ color: active.color }}>
                {active.value}
              </span>
              <span className="text-xs text-gray-400 mt-0.5">{active.label}</span>
              <span className="text-[10px] text-gray-500 mt-0.5">{active.percent.toFixed(1)}%</span>
            </>
          ) : (
            <>
              <span className="text-2xl font-bold text-white">{centerValue ?? total}</span>
              {centerLabel && <span className="text-xs text-gray-400 mt-0.5">{centerLabel}</span>}
            </>
          )}
        </div>
      </div>
      <div className="grid grid-cols-1 gap-2 w-full">
        {slices.map((s, i) => (
          <div
            key={i}
            onMouseEnter={() => setHoverIdx(i)}
            onMouseLeave={() => setHoverIdx(null)}
            className={`flex items-center justify-between text-sm px-2 py-1.5 rounded-md cursor-pointer transition-colors ${
              hoverIdx === i ? 'bg-gray-800/70' : 'hover:bg-gray-800/40'
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: s.color }} />
              <span className="text-gray-300">{s.label}</span>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-gray-500 text-xs">{s.percent.toFixed(1)}%</span>
              <span className="text-white font-medium tabular-nums">{s.value}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Bar Chart ─────────────────────────────────────────────────────────────

export interface BarChartItem {
  label: string;
  value: number;
  color: string;
}

export function BarChart({
  data,
  valueFormatter,
}: {
  data: BarChartItem[];
  valueFormatter?: (n: number) => string;
}) {
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);
  const total = data.reduce((s, d) => s + d.value, 0);
  const max = Math.max(...data.map((d) => d.value), 1);

  if (data.length === 0 || data.every((d) => d.value === 0)) {
    return <EmptyChart height={180} />;
  }

  return (
    <div className="flex flex-col gap-4">
      {data.map((d, i) => {
        const pct = (d.value / max) * 100;
        const sharePct = total === 0 ? 0 : (d.value / total) * 100;
        const isHovered = hoverIdx === i;
        const dim = hoverIdx !== null && !isHovered;

        return (
          <div
            key={i}
            onMouseEnter={() => setHoverIdx(i)}
            onMouseLeave={() => setHoverIdx(null)}
            className="cursor-pointer group"
            style={{ opacity: dim ? 0.55 : 1, transition: 'opacity 150ms' }}
          >
            <div className="flex items-center justify-between text-sm mb-1.5">
              <span className="text-gray-300 flex items-center gap-2">
                {d.label}
                <span
                  className="text-[10px] text-gray-500 tabular-nums transition-opacity"
                  style={{ opacity: isHovered ? 1 : 0 }}
                >
                  {sharePct.toFixed(1)}%
                </span>
              </span>
              <span className="text-white font-medium tabular-nums">
                {valueFormatter ? valueFormatter(d.value) : d.value}
              </span>
            </div>
            <div className="h-2.5 bg-gray-800 rounded-full overflow-hidden relative">
              <div
                className="h-full rounded-full transition-all duration-300"
                style={{
                  width: `${pct}%`,
                  backgroundColor: d.color,
                  boxShadow: isHovered ? `0 0 12px ${d.color}80` : 'none',
                }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ─── Empty State ───────────────────────────────────────────────────────────

function EmptyChart({ height }: { height: number }) {
  return (
    <div
      className="flex items-center justify-center text-gray-600 text-sm border border-dashed border-gray-800 rounded-xl"
      style={{ height }}
    >
      No data available
    </div>
  );
}
