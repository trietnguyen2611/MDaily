import React from 'react'
import { Search } from 'lucide-react'
import './SearchBar.css'

interface SearchBarProps {
  value: string
  onChange: (val: string) => void
}

export const SearchBar: React.FC<SearchBarProps> = ({ value, onChange }) => {
  return (
    <div className="search-bar-container">
      <div className="search-bar">
        <Search size={18} className="search-icon" />
        <input 
          type="text" 
          placeholder="Tìm kiếm chi tiêu, ghi chú..." 
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      </div>
    </div>
  )
}
