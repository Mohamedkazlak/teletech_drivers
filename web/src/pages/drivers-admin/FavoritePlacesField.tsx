import { useTranslation } from 'react-i18next'
import type { Place } from '../../api/types'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { controlClass } from '../../components/ui/styles'
import { MAX_FAVORITE_PLACES } from '../../lib/favorites'
import { localizedName } from '../../lib/names'

type FavoritePlacesFieldProps = {
  places: Place[]
  selectedIds: string[]
  onChange: (ids: string[]) => void
  error?: string
  disabled?: boolean
}

export function FavoritePlacesField({
  places,
  selectedIds,
  onChange,
  error,
  disabled = false,
}: FavoritePlacesFieldProps) {
  const { t, i18n } = useTranslation()
  const atCap = selectedIds.length >= MAX_FAVORITE_PLACES
  const hint = atCap ? t('driverAdmin.favoritesFull') : t('driverAdmin.favoritesHint')

  function add(id: string) {
    if (!id || selectedIds.includes(id) || selectedIds.length >= MAX_FAVORITE_PLACES) return
    onChange([...selectedIds, id])
  }

  function remove(id: string) {
    onChange(selectedIds.filter((item) => item !== id))
  }

  const remaining = places.filter((place) => !selectedIds.includes(place.id))

  return (
    <FormField id="driver-favorites" label={t('driverAdmin.favorites')} error={error} hint={hint}>
      <select
        id="driver-favorites"
        className={controlClass}
        value=""
        disabled={disabled || atCap}
        aria-describedby={fieldDescribedBy('driver-favorites', error, hint)}
        onChange={(event) => {
          add(event.target.value)
        }}
      >
        <option value="">{t('driverAdmin.addFavorite')}</option>
        {remaining.map((place) => (
          <option key={place.id} value={place.id}>
            {localizedName(i18n.language, place.name_en, place.name_ar)}
          </option>
        ))}
      </select>
      {selectedIds.length > 0 ? (
        <ul className="mt-2 flex flex-wrap gap-2">
          {selectedIds.map((id) => {
            const place = places.find((item) => item.id === id)
            const name = place ? localizedName(i18n.language, place.name_en, place.name_ar) : id
            return (
              <li key={id}>
                <button
                  type="button"
                  className="inline-flex min-h-10 items-center gap-2 rounded-chip bg-pale px-3 text-sm font-semibold text-navy"
                  aria-label={t('driverAdmin.removeFavorite', { name })}
                  onClick={() => remove(id)}
                  disabled={disabled}
                >
                  {name}
                  <span aria-hidden="true">×</span>
                </button>
              </li>
            )
          })}
        </ul>
      ) : null}
    </FormField>
  )
}
