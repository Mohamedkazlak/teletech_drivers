/** Motion tokens from DESIGN.md, for `motion/react` (seconds, cubic-bezier arrays). */
export const EASE_OUT = [0.23, 1, 0.32, 1] as const
export const EASE_IN_OUT = [0.77, 0, 0.175, 1] as const

export const DURATION = {
  press: 0.12,
  quick: 0.18,
  standard: 0.26,
  emphasized: 0.42,
} as const

const STAGGER_MS = [0, 50, 90, 120, 145, 165] as const

/** List entrance delay in ms: non-uniform, capped at the last step. */
export function staggerDelay(index: number): number {
  return STAGGER_MS[Math.min(Math.max(index, 0), STAGGER_MS.length - 1)]
}
