import { useTranslation } from 'react-i18next'
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

export type ChartPoint = {
  label: string
  value: number
}

type TooltipProps = {
  active?: boolean
  label?: string
  payload?: { value?: number }[]
}

function ChartTooltip({ active, label, payload }: TooltipProps) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-[10px] bg-navy px-3 py-2 text-white shadow-float">
      <p className="text-xs text-white/70">{label}</p>
      <p className="text-base font-semibold tabular">{payload[0]?.value ?? 0}</p>
    </div>
  )
}

export function BarChartCard({ title, points }: { title: string; points: ChartPoint[] }) {
  const { t } = useTranslation()
  return (
    <section className="flex flex-col rounded-card border border-line bg-white p-5 animate-rise">
      <h2 className="text-[15px] font-semibold text-navy">{title}</h2>
      {points.length === 0 ? (
        <p className="mt-4 text-sm text-ink-muted">{t('common.noData')}</p>
      ) : (
        <div className="mt-4 h-72 min-h-64 flex-1">
          <ul className="sr-only">
            {points.map((point) => (
              <li key={point.label}>
                {point.label}: {point.value}
              </li>
            ))}
          </ul>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={points} margin={{ top: 8, right: 4, bottom: 0, left: -18 }}>
              <defs>
                <linearGradient id="bar-fill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#2F7BEA" />
                  <stop offset="100%" stopColor="#0B4DA2" />
                </linearGradient>
              </defs>
              <CartesianGrid vertical={false} stroke="#E3E8F1" strokeDasharray="4 4" />
              <XAxis
                dataKey="label"
                tickLine={false}
                axisLine={false}
                tick={{ fill: '#5B6B86', fontSize: 12 }}
                interval={0}
                height={44}
              />
              <YAxis
                allowDecimals={false}
                tickLine={false}
                axisLine={false}
                tick={{ fill: '#5B6B86', fontSize: 12 }}
              />
              <Tooltip
                cursor={{ fill: 'rgb(234 240 250 / 0.7)', radius: 10 } as object}
                content={<ChartTooltip />}
              />
              <Bar
                dataKey="value"
                name={title}
                fill="url(#bar-fill)"
                radius={[10, 10, 4, 4]}
                maxBarSize={44}
                animationDuration={700}
                animationEasing="ease-out"
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}
    </section>
  )
}
