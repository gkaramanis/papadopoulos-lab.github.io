-- group-by-year.lua
-- Pandoc Lua filter to group bibliography entries by year with a year header

function Div(el)
  if el.identifier == "refs" then
    local years = {}
    local by_year = {}

    -- Collect all references and group by year
    for _, item in ipairs(el.content) do
      if item.t == "Div" and item.identifier:match("^ref%-") then
        local year
        for _, block in ipairs(item.content) do
          if block.t == "Para" then
            local text = pandoc.utils.stringify(block)
            year = text:match("(%d%d%d%d)")
            if year then break end
          end
        end
        year = year or "No year"
        if not by_year[year] then
          by_year[year] = {}
          table.insert(years, year)
        end
        table.insert(by_year[year], item)
      end
    end

    -- Sort years descending
    table.sort(years, function(a, b) return a > b end)

    -- Build new content with year headers
    local new_content = {}
    for _, year in ipairs(years) do
      table.insert(new_content, pandoc.Header(2, year))
      for _, ref in ipairs(by_year[year]) do
        table.insert(new_content, ref)
      end
    end

    return pandoc.Div(new_content, el.attr)
  end
end
