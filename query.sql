-- 1. Give album title, album release date and album price of all Neil Young's albums released after 1st January 2015.
select distinct a.albumTitle, a.albumReleaseDate, a.albumPrice
from albums a, table(a.albumArtists) v
where v.artistName = 'Neil Young'
and a.albumReleaseDate > '1-Jan-2015'
/
-- 2. Give album title and artist name for albums released only in MP3 format. Order by album title.
select a.albumTitle, v.artistName
from albums a, table(a.albumArtists) v
where value(a) IS OF (mp3_type)
order by a.albumTitle
/
-- 3. Give lowest rated MP3 album (i.e. album with the lowest average review score). Show album
-- title and the average score. Exclude albums with only one review.
select title, min(avgScore)
from
(select a.albumTitle as title, avg(r.reviewScore) as avgScore
from albums a, table(a.albumReviews) r
where value(a) is of (mp3_type)
group by a.albumTitle
having count(r.reviewText) > 1 
) 
group by title
/
-- 4. Are there any albums released on all media, i.e. on MP3, audio CD and vinyl? Show album
-- title and order by album title.
select a.albumTitle
from albums a, albums b, albums c
where value(a) is of (disk_type)
and value(b) is of (disk_type)
and value(c) is of (mp3_type)
and value(a).mediaType = 'Vinyl'
and value(b).mediaType = 'Audio CD'
and a.albumTitle = b.albumTitle
and b.albumTitle = c.albumTitle
order by a.albumTitle
/
select * from albums
-- 5. Implement the method discountPrice() that returns a discounted price using the following
-- business rule:
-- a. for audio CDs released more than one year ago the discount is 20%
-- b. for vinyl records released more than one year ago the discount is 15%
-- c. for MP3 downloads released more than two years ago the discount is 10%
-- Note that the signature of the discountPrice method is included in the original OMDB script for
-- both disk_type and mp3_type subtypes.
create or replace type body disk_type 
as member function discountPrice
return number is
	discount_price := 0;
begin
	if albumReleaseDate < add_months(trunc(sysdate), -12) then
		case mediaType
		when 'Vinyl' then 
			discount_price := albumPrice * 0.2;
		when 'Audio CD' then
			discount_price := albumPrice * 0.15;
		end case;
	end if;
	return discount_price;
end;
/
create or replace type body mp3_type 
as member function discountPrice
return number is
	discount_price := 0;
begin
	if albumReleaseDate < add_months(trunc(sysdate), -12*2) then
		discount_price := albumPrice * 0.1;
	end if;
	return discount_price;
end;
/
-- 6. Create a view all_albums that includes the columns: album title, media type ('MP3', ‘Vinyl’,
-- ‘Audio CD’), album price, and discount (album price – discount price). Use this view to find
-- the album that received the largest discount; show all view columns. (5 marks)
create view all_albums as
select a.albumTitle, a.mediaType, a.albumPrice, (a.albumPrice - a.discountPrice()) as discount
from ablums a
where value(a) IS OF (disk_type)
union all
select b.albumTitle, 'MP3', b.albumPrice, (b.albumPrice - b.discountPrice()) as discount
from ablums b
where value(b) IS OF (mp3_type)
/
select * 
from all_albums
where (albumTitle, discount) in (
	select albumTitle, max(discount)
	from all_albums
	group by albumTitle
)
/
-- 7. Now, modify the view all_albums to also include the column album used price for disks; set
-- album used price to zero for MP3 albums. Use this view to find the most expensive used
-- album; show all view columns. (5 marks)
create or update view all_albums as
select a.albumTitle, a.mediaType, a.albumPrice, (a.albumPrice - a.discountPrice()) as discount, diskUsedPrice
from ablums a
where value(a) IS OF (disk_type)
union all
select b.albumTitle, 'MP3' as mediaType, b.albumPrice, (b.albumPrice - b.discountPrice()) as discount, 0 as diskUsedPrice
from ablums b
where value(b) IS OF (mp3_type)
/
select *
from all_albums
where (albumTitle, diskUsedPrice) in (
	select albumTitle, max(diskUsedPrice)
	from all_albums
)
/
-- 8. Implement the method containsText (pString1, pString2) that returns 1 if pString1 contains
-- pString, and 0 if it does not. Use this method to find albums with reviews that contain the word
-- 'Great'. Show album title, review text, review score. Note that the signature of the containsText
-- method is included in the original OMDB script. (5 marks)
create or replace type body album_type 
as member function containsText(pString1 varchar2, pString2 varchar2) 
return integer is
	is_contain := 0;
begin
	if instr(pString1, pString2) != 0 then
		is_contain := 1;
	end if;
	return is_contain;
end;
/
select albumTitle, r.reviewText, r.reviewScore
from albums a, table(a.albumReviews) r
where containsText(r.reviewText, 'Great')
/