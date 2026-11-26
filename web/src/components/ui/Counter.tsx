import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useEffect, useRef, useState } from 'react'
import { DURATION, EASE_OUT } from '../../lib/motion'

type CounterProps = {
  value: number
  className?: string
}

const FLASH_MS = 600

/*
  A number that only moves when it changes after the first render: each
  changed digit rolls in from below and the figure briefly takes the signal
  tint. The first value appears as is, so zeros never "count up".
*/
export function Counter({ value, className = '' }: CounterProps) {
  const reduce = useReducedMotion()
  const previous = useRef(value)
  const [changed, setChanged] = useState(false)

  useEffect(() => {
    if (previous.current === value) return
    previous.current = value
    setChanged(true)
    const timer = window.setTimeout(() => setChanged(false), FLASH_MS)
    return () => window.clearTimeout(timer)
  }, [value])

  const digits = Array.from(String(value))

  return (
    <span
      data-testid="counter"
      data-changed={changed ? 'true' : undefined}
      className={`inline-flex tabular transition-colors duration-[600ms] ease-[var(--ease-out)] data-[changed=true]:text-signal ${className}`}
    >
      <span className="sr-only">{value}</span>
      {digits.map((digit, index) => (
        <span
          key={digits.length - index}
          aria-hidden="true"
          className="relative inline-block overflow-hidden"
        >
          <AnimatePresence initial={false} mode="popLayout">
            <motion.span
              key={digit}
              className="inline-block"
              initial={reduce ? { opacity: 0 } : { y: '0.6em', opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={reduce ? { opacity: 0 } : { y: '-0.6em', opacity: 0 }}
              transition={{ duration: DURATION.emphasized, ease: EASE_OUT }}
            >
              {digit}
            </motion.span>
          </AnimatePresence>
        </span>
      ))}
    </span>
  )
}
