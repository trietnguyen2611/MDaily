import React from 'react'
import { ChevronDown } from 'lucide-react'
import './CustomSelect.css'

export type SelectOption = {
  value: string
  label: string
  icon?: React.ReactNode
}

interface CustomSelectProps {
  options: SelectOption[]
  value: string
  onChange: (value: string) => void
  placeholder?: string
}

export const CustomSelect: React.FC<CustomSelectProps> = ({
  options = [],
  value,
  onChange,
  placeholder = 'Chọn...'
}) => {
  const selectedOption = (options || []).find(opt => opt.value === value)

  return (
    <div className="custom-select-container">
      <div className="custom-select-trigger">
        <span className="custom-select-value">
          {selectedOption?.icon && <span className="custom-select-icon">{selectedOption.icon}</span>}
          {selectedOption ? selectedOption.label : placeholder}
        </span>
        <ChevronDown size={16} className="custom-select-arrow" />
      </div>

      {/* Native iOS Picker Select Overlay */}
      <select
        className="native-select-overlay"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        aria-label={selectedOption ? selectedOption.label : placeholder}
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
    </div>
  )
}
