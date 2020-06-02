function Init()
	local m = NewWebsiteModule()
	m.ID                         = 'bcf6bf0a1b5d4cffa6cc6743e29ee5f2'
	m.Category                   = 'Turkish'
	m.Name                       = 'Manga-Tr'
	m.RootURL                    = 'https://manga-tr.com'
	m.OnGetInfo                  = 'GetInfo'
	m.OnGetPageNumber            = 'GetPageNumber'
	m.OnGetNameAndLink           = 'GetNameAndLink'
end

function GetInfo()
	if HTTP.GET(MANGAINFO.URL) then
		local x=TXQuery.Create(HTTP.Document)
		MANGAINFO.CoverLink = x.XPathString('//img[@class="thumbnail"]/@src')
		MANGAINFO.Title     = Trim(x.XPathString('//title/substring-before(., "- Çevrimiçi Türkçe Manga")'))
		MANGAINFO.Authors   = x.XPathString('//table[2]/tbody/tr[2]/td[1]')
		MANGAINFO.Artists   = x.XPathString('//table[2]/tbody/tr[2]/td[2]')
		MANGAINFO.Genres    = Trim(x.XPathString('//table[2]/tbody/tr[2]/td[3]'))
		MANGAINFO.Summary   = x.XPathString('//div[@class="well"]/text()')

		local info = x.XPathString('//*[@slug]/@slug')
		local pages = 2
		local p = 1
		while p <= pages do
			if p >= 1 then
				HTTP.Reset()
				HTTP.Headers.Values['Cache-Control'] = 'no-cache'
				HTTP.Headers.Values['content-type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
				HTTP.Headers.Add('X-Requested-With: XMLHttpRequest')
				if HTTP.POST(MODULE.RootURL .. '/cek/fetch_pages_manga.php?manga_cek='..info, 'page='..p) then
					x=TXQuery.Create(HTTP.Document)
				else
					break
				end
			end

			if p == pages then
				local pg = x.XPathString('//*[@class="last"]/a/@data-page')
				if pg ~= '' then pages = tonumber(pg) end
			end
			local v=x.XPath('//tr/td[1]/a')
			for i=1,v.Count do
				local v1=v.Get(i)
				MANGAINFO.ChapterLinks.Add(v1.GetAttribute('href'))
				MANGAINFO.ChapterNames.Add(v1.ToString())
			end
			p = p + 1
		end
		InvertStrings(MANGAINFO.ChapterLinks,MANGAINFO.ChapterNames)
		return no_error
	else
		return net_problem
	end
end

function GetNameAndLink()
	if HTTP.GET(MODULE.RootURL .. '/manga-list.html?listType=allABC') then
		local x=TXQuery.Create(HTTP.Document)
		x.XPathHREFAll('//*[@data-toggle="mangapop"]/b/a', LINKS, NAMES)
		return no_error
	else
		return net_problem
	end
end

function GetPageNumber()
	TASK.PageLinks.Clear()
	if HTTP.GET(MaybeFillHost(MODULE.RootURL, URL)) then
		local x=TXQuery.Create(HTTP.Document)
		x.XPathStringAll('//img[@class="chapter-img"]/@src', TASK.PageLinks)
		return true
	else
		return false
	end
end