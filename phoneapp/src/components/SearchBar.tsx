import React, { useState, useRef, useEffect } from 'react'
import { Search } from 'lucide-react'
import './SearchBar.css'

interface SearchBarProps {
  value: string
  onChange: (val: string) => void
}

export const SearchBar: React.FC<SearchBarProps> = ({ value, onChange }) => {
  const [isExpanded, setIsExpanded] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        if (!value) {
          setIsExpanded(false)
        }
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [value])

  const handleContainerClick = () => {
    if (!isExpanded) {
      setIsExpanded(true)
      setTimeout(() => inputRef.current?.focus(), 100)
    }
  }

  return (
    <div className="search-bar-container" ref={containerRef}>
      <div 
        className={`search-bar ${isExpanded ? 'expanded' : 'collapsed'}`}
        onClick={handleContainerClick}
      >
        <Search size={18} className="search-icon" />
        <input 
          ref={inputRef}
          type="text" 
          placeholder="Tìm kiếm..." 
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={() => setIsExpanded(true)}
        />
      </div>
    </div>
  )
}
