import { useRef } from 'react'
import { QRCodeCanvas } from 'qrcode.react'
import { useTranslation } from 'react-i18next'
import { useAttendanceQr } from '../../api/use-attendance'
import { PageHeading } from '../../components/layout/AppShell'
import { primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'

export function AttendanceQrPage() {
  const { t } = useTranslation()
  const qr = useAttendanceQr()
  const canvasHost = useRef<HTMLDivElement>(null)

  function download() {
    const canvas = canvasHost.current?.querySelector('canvas')
    if (!canvas) return
    const link = document.createElement('a')
    link.href = canvas.toDataURL('image/png')
    link.download = 'attendance-qr.png'
    link.click()
  }

  return (
    <section className="flex flex-col gap-4 print:gap-2">
      <PageHeading title={t('attendance.qr')} />
      {qr.isPending ? <p>{t('common.loading')}</p> : null}
      {qr.isError ? <p className="text-danger">{messageForApiError(qr.error, t)}</p> : null}
      {qr.data ? (
        <div className="flex flex-col items-start gap-4 rounded-card border border-line bg-white p-6">
          <h2 className="text-xl font-semibold text-navy">{qr.data.hq_name}</h2>
          <div ref={canvasHost}>
            <QRCodeCanvas value={qr.data.payload} size={240} includeMargin />
          </div>
          <div className="flex gap-2 print:hidden">
            <button type="button" className={primaryButtonClass} onClick={() => window.print()}>
              {t('attendance.print')}
            </button>
            <button type="button" className={secondaryButtonClass} onClick={download}>
              {t('attendance.download')}
            </button>
          </div>
        </div>
      ) : null}
    </section>
  )
}
