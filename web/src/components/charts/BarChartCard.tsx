import { useTranslation } from 'react-i18next'
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

export type ChartPoint = {
  label: string
  value: number
}

export function BarChartCard({ title, points }: { title: string; points: ChartPoint[] }) {
  const { t } = useTranslation()
  return (
    <section className="rounded-card border border-pale bg-white p-5">
      <h2 className="text-base font-bold text-navy">{title}</h2>
      {points.length === 0 ? (
        <p className="mt-4 text-sm text-navy/75">{t('common.noData')}</p>
      ) : (
        <div className="mt-4 h-64">
          <ul className="sr-only">
            {points.map((point) => (
              <li key={point.label}>
                {point.label}: {point.value}
              </li>
            ))}
          </ul>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={points}>
              <XAxis dataKey="label" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Bar dataKey="value" name={title} fill="#0B4DA2" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}
    </section>
  )
}
