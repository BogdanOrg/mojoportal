create or replace function drop_type
(
	varchar(100) --: typename
) returns int4 
as '
declare
	_typename alias for $1;
	_rowcount int4;

begin

_rowcount := 0;
perform 1 from pg_class where
	  relname like _typename limit 1;
	
if found then
	EXECUTE ''DROP TYPE '' || _typename || '' CASCADE;'';
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
end if;
return _rowcount; 
end'
security definer language plpgsql;

CREATE OR REPLACE FUNCTION public.monthname(timestamptz)
  RETURNS varchar(10) AS
'
declare
	_date alias for $1;
	_month int;
	_monthname varchar(10);
begin
    _month := date_part(''month'', _date);
    _monthname := ''January'';
    if _month = 2 then
        _monthname := ''February'';
    end if;
    if _month = 3 then
        _monthname := ''March'';
    end if;
    if _month = 4 then
        _monthname := ''April'';
    end if;
    if _month = 5 then
        _monthname := ''May'';
    end if;
    if _month = 6 then
        _monthname := ''June'';
    end if;
    if _month = 7 then
        _monthname := ''July'';
    end if;
    if _month = 8 then
        _monthname := ''August'';
    end if;
    if _month = 9 then
        _monthname := ''September'';
    end if;
    if _month = 10 then
        _monthname := ''October'';
    end if;
    if _month = 11 then
        _monthname := ''November'';
    end if;
    if _month = 12 then
        _monthname := ''December'';
    end if;
    return _monthname;    
end;'
  LANGUAGE 'plpgsql' VOLATILE SECURITY DEFINER;

create or replace function mp_blogcomment_delete
(
	int --:blogcommentid $1
) returns int4 
as '
declare
	_blogcommentid alias for $1;
	 _moduleid int;
	 _itemid int;
	_rowcount int;
begin

select into _moduleid, _itemid 
            moduleid, itemid
from	mp_blogcomments
where blogcommentid = _blogcommentid;

delete 
from 	mp_blogcomments
where	blogcommentid = _blogcommentid;

GET DIAGNOSTICS _rowcount = ROW_COUNT;

update mp_blogs
set commentcount = commentcount - 1
where moduleid = _moduleid and itemid = _itemid;

update mp_blogstats
set 	commentcount = commentcount - 1
where moduleid = _moduleid;   

return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blogcomment_delete
(
	int --:blogcommentid $1
) to public;


create or replace function mp_blogcomment_insert
(
	int, --:moduleid $1
	int, --:itemid $2
	varchar(100), --:name $3
	varchar(100), --:title $4
	varchar(200), --:url $5
	text, --:comment $6
	timestamp --:datecreated $7
) returns int4
as '
declare
	_moduleid alias for $1;
	_itemid alias for $2;
	_name alias for $3;
	_title alias for $4;
	_url alias for $5;
	_comment alias for $6;
	_datecreated alias for $7;
	_rowcount int4;
begin

insert into mp_blogcomments
(
    	moduleid,
	itemid,
    	name,
    	title,
	url,
    	comment,
	datecreated
)
values
(
    _moduleid,
    _itemid,
    _name,
    _title,
    _url,
    _comment,
    _datecreated
);

update mp_blogs
set commentcount = commentcount + 1
where moduleid = _moduleid and itemid = _itemid;

update mp_blogstats
set 	commentcount = commentcount + 1
where moduleid = _moduleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blogcomment_insert
(
	int, --:moduleid $1
	int, --:itemid $2
	varchar(100), --:name $3
	varchar(100), --:title $4
	varchar(200), --:url $5
	text, --:comment $6
	timestamp --:datecreated $7
) to public;

select drop_type('mp_blogcomments_select_type');
CREATE TYPE public.mp_blogcomments_select_type AS (
	blogcommentid int4,
	itemid int4,
	moduleid int4,
	name varchar(100),
	title varchar(100),
	url varchar(200),
	comment text,
	datecreated timestamp
);
create or replace function mp_blogcomments_select
(
	int, --:moduleid $1
	int --:itemid $2
) returns setof mp_blogcomments_select_type 
as '
select		
	blogcommentid,
	itemid, 
	moduleid, 
	name, 
	title, 
	url, 
	comment, 
	datecreated
from        mp_blogcomments
where
    		moduleid = $1
		and itemid = $2
   order by
   	blogcommentid,  datecreated desc; '
security definer language sql;
grant execute on function mp_blogcomments_select
(
	int, --:moduleid $1
	int --:itemid $2
) to public;

select drop_type('mp_blogstats_select_type');
CREATE TYPE public.mp_blogstats_select_type AS (
		
			moduleid int4 , 
			entrycount int4 ,
			commentcount int4 
);
create or replace function mp_blogstats_select
(
	int --:moduleid $1
) returns setof mp_blogstats_select_type 
as '
select		
			moduleid, 
			entrycount,
			commentcount
from       		 mp_blogstats
where
    			moduleid = $1; '
security definer language sql;
grant execute on function mp_blogstats_select
(
	int --:moduleid $1
) to public;







create or replace function mp_blog_delete
(
	int --:itemid $1
) returns int4 
as '
declare
	_itemid alias for $1;
	 _moduleid int;
	_rowcount int;
begin

select into _moduleid moduleid 
from mp_blogs where itemid = _itemid;

delete from 
    mp_blogs
where
    itemid = _itemid;
    
GET DIAGNOSTICS _rowcount = ROW_COUNT;

update mp_blogstats
set 	entrycount = entrycount - 1
where moduleid = _moduleid;   

return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blog_delete
(
	int --:itemid $1
) to public;

create or replace function mp_blog_insert
(
	int, --:moduleid $1
	varchar(100), --:username $2
	varchar(100), --:title $3
	varchar(512), --:excerpt $4
	text, --:description $5
	timestamp, --:startdate $6
	bool, --:isinnewsletter $7
	bool, --:includeinfeed $8
	varchar(50) --:category $9
) returns int4 
as '
declare
	_moduleid alias for $1;
	_username alias for $2;
	_title alias for $3;
	_excerpt alias for $4;
	_description alias for $5;
	_startdate alias for $6;
	_isinnewsletter alias for $7;
	_includeinfeed alias for $8;
	_category alias for $9;
	_itemid int4;
	t_found int;
	
begin

insert into mp_blogs
(
	moduleid,
	createdbyuser,
	createddate,
	title,
	excerpt,
	description,
	startdate,
	isinnewsletter,
	includeinfeed,
	category
)
values
(
    _moduleid,
    _username,
    current_timestamp(3),
    _title,
    _excerpt,
    _description,
    _startdate,
    _isinnewsletter,
    _includeinfeed,
    _category 
);

select into _itemid cast(currval(''mp_blogs_itemid_seq'') as int4);
select into t_found 1 from mp_blogstats where moduleid = _moduleid limit 1;
if found then
		update mp_blogstats
		set 	entrycount = entrycount + 1
		where moduleid = _moduleid;
else
		insert into mp_blogstats(moduleid, entrycount)
		values (_moduleid, 1);   
end if;
return _itemid;
end'
security definer language plpgsql;
grant execute on function mp_blog_insert
(
	int, --:moduleid $1
	varchar(100), --:username $2
	varchar(100), --:title $3
	varchar(512), --:excerpt $4
	text, --:description $5
	timestamp, --:startdate $6
	bool, --:isinnewsletter $7
	bool, --:includeinfeed $8
	varchar(50) --:category $9
) to public;

select drop_type('mp_blog_select_type');
CREATE TYPE public.mp_blog_select_type AS (
	itemid int4 ,
	moduleid int4 ,
	createdbyuser varchar(100),
	createddate timestamp,
	title varchar(100),
	excerpt varchar(512),
	description text,
	startdate timestamp,
	isinnewsletter bool,
	includeinfeed bool,
	category varchar(50),
	commentcount varchar(20) 
);
create or replace function mp_blog_select
(
	int, --:moduleid $1
	timestamp --:begindate $2
) returns setof mp_blog_select_type 
as '
declare
	_moduleid alias for $1;
	_begindate alias for $2;
	 _rowstoget int;
	_rec mp_blog_select_type%ROWTYPE;

begin

_rowstoget := coalesce((select settingvalue::text::int4 from mp_modulesettings 
	where settingname = ''BlogEntriesToShowSetting'' 
	and moduleid = _moduleid limit 1),1);
for _rec in
	select		
		itemid, 
		moduleid, 
		createdbyuser, 
		createddate, 
		title, 
		excerpt, 
		description, 
		startdate,
		isinnewsletter, 
		includeinfeed ,
		category,
		to_char(commentcount, ''99999999999'') as commentcount
	from        mp_blogs
	where
	    (moduleid = _moduleid) and (_begindate >= startdate)
	   order by
		startdate desc
	limit _rowstoget
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_blog_select
(
	int, --:moduleid $1
	timestamp --:begindate $2
) to public;

-------------------------------------------


create or replace function mp_blog_selectbyenddate
(
	int, --:moduleid $1
	date --:enddate $2
) returns setof mp_blog_select_type 
as '
declare
	_moduleid alias for $1;
	_enddate alias for $2;
	 _rowstoget int;
	_rec mp_blog_select_type%ROWTYPE;

begin

_rowstoget := coalesce((select settingvalue::text::int4 from mp_modulesettings 
	where settingname = ''BlogEntriesToShowSetting'' 
	and moduleid = _moduleid limit 1),1);
for _rec in
	select		
		itemid, 
		moduleid, 
		createdbyuser, 
		createddate, 
		title, 
		excerpt, 
		description, 
		startdate,
		isinnewsletter, 
		includeinfeed ,
		category,
		to_char(commentcount, ''99999999999'') as commentcount
	from        mp_blogs
	where
	    (moduleid = _moduleid) and (startdate <= _enddate)
	   order by
		itemid desc,  startdate desc
	limit _rowstoget
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_blog_selectbyenddate
(
	int, --:moduleid $1
	date --:enddate $2
) to public;



-------------------------------------------------

select drop_type('mp_blog_selectarchivebymonth_type');
CREATE TYPE public.mp_blog_selectarchivebymonth_type AS (
		month int4 , 
		monthname varchar(10) ,
		year int4 , 
		day int4 , 
		count int4 
);
create or replace function mp_blog_selectarchivebymonth
(
	int --:moduleid $1
) returns setof mp_blog_selectarchivebymonth_type 
as '
select 	
		cast(date_part(''month'', startdate) as int4) as month, 
		monthname(startdate) as monthname,
		cast(date_part(''year'', startdate) as int4) as year, 
		1 as day, 
		cast(count(*) as int4) as count 
from 		mp_blogs
 
where 	moduleid = $1 
group by 	date_part(''year'', startdate), 
		date_part(''month'', startdate),
		monthname(startdate)
order by 	year desc, month desc; '
security definer language sql;
grant execute on function mp_blog_selectarchivebymonth
(
	int --:moduleid $1
) to public;

create or replace function mp_blog_selectbymonth
(
	int, --:month $1
	int, --:year $2
	int --:moduleid $3
) returns setof mp_blogs 
as '
select	*
from 		mp_blogs
where 	moduleid = $3
		and date_part(''year'', startdate)  = $2 
		and date_part(''month'', startdate)  = $1
order by	 startdate desc; '
security definer language sql;
grant execute on function mp_blog_selectbymonth
(
	int, --:month $1
	int, --:year $2
	int --:moduleid $3
) to public;

select drop_type('mp_blog_selectone_type');
CREATE TYPE public.mp_blog_selectone_type AS (
		itemid int4 ,
		moduleid int4 ,
		createdbyuser varchar(100),
		createddate timestamp,
		title varchar(100),
		excerpt varchar(512),
		description text , 
		startdate timestamp , 
		isinnewsletter bool ,
		includeinfeed bool,
		category varchar(50)
);
create or replace function mp_blog_selectone
(
	int --:itemid $1
) returns setof mp_blog_selectone_type 
as '
select		itemid,
		moduleid,
		createdbyuser,
		createddate,
		title, 
		excerpt, 
		description, 
		startdate, 
		isinnewsletter,
		includeinfeed,
		category
			
from	mp_blogs
where   (itemid = $1); '
security definer language sql;
grant execute on function mp_blog_selectone
(
	int --:itemid $1
) to public;

create or replace function mp_blog_update
(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(100), --:username $3
	varchar(100), --:title $4
	varchar(512), --:excerpt $5
	text, --:description $6
	timestamp, --:startdate $7
	bool, --:isinnewsletter $8
	bool, --:includeinfeed $9
	varchar(50) --:category $10
   
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_username alias for $3;
	_title alias for $4;
	_excerpt alias for $5;
	_description alias for $6;
	_startdate alias for $7;
	_isinnewsletter alias for $8;
	_includeinfeed alias for $9;
	_category alias for $10;
	_rowcount int4;
begin

update mp_blogs
set 
moduleid = _moduleid,
createdbyuser = _username,
createddate = current_timestamp(3),
title = _title,
excerpt = _excerpt,
description = _description,
startdate = _startdate,
isinnewsletter = _isinnewsletter,
includeinfeed = _includeinfeed,
category = _category
where 
itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blog_update
(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(100), --:username $3
	varchar(100), --:title $4
	varchar(512), --:excerpt $5
	text, --:description $6
	timestamp, --:startdate $7
	bool, --:isinnewsletter $8
	bool, --:includeinfeed $9
	varchar(50) --:category $10
   
) to public;

create or replace function mp_forumposts_countbythread
(
	int --:threadid $1
) returns int4
as '
select	cast(count(*) as int4)
from		mp_forumposts
where	threadid = $1; '
security definer language sql;
grant execute on function mp_forumposts_countbythread
(
	int --:threadid $1
) to public;

create or replace function mp_forumposts_delete
(
	int --:postid $1
) returns int4
as '
declare
	_postid alias for $1;
	_rowcount int4;
begin

	delete from  mp_forumposts
where postid = _postid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumposts_delete
(
	int --:postid $1
) to public;

create or replace function mp_forumposts_insert
(
	int, --:threadid $1
	varchar(255), --:subject $2
	text, --:post $3
	bool, --:approved $4
	int, --:userid $5
	timestamp --:postdate $6
) returns int4 
as '
declare
	_threadid alias for $1;
	_subject alias for $2;
	_post alias for $3;
	_approved alias for $4;
	_userid alias for $5;
	_postdate alias for $6;
	 _threadsequence int;
	_itemid int;

begin

_threadsequence := (select coalesce(max(threadsequence) + 1,1) from mp_forumposts where threadid = _threadid);
insert into		mp_forumposts
(
			threadid,
			subject,
			post,
			approved,
			userid,
			threadsequence,
			postdate
)
values
(
			_threadid,
			_subject,
			_post,
			_approved,
			_userid,
			_threadsequence,
			_postdate
);

select into _itemid cast(currval(''mp_forumposts_postid_seq'') as int4); 
return _itemid;
end'
security definer language plpgsql;
grant execute on function mp_forumposts_insert
(
	int, --:threadid $1
	varchar(255), --:subject $2
	text, --:post $3
	bool, --:approved $4
	int, --:userid $5
	timestamp --:postdate $6
) to public;

select drop_type('mp_forumposts_selectallbythread_type');
CREATE TYPE public.mp_forumposts_selectallbythread_type AS (
	postid int4 ,
	threadid int4 ,
	threadsequence int4 ,
	subject varchar(255) ,
	postdate timestamp ,
	approved bool ,
	userid int4 ,
	sortorder int4 ,
	post text,
	forumid int4 ,
	mostrecentpostuser varchar(50) ,
	startedby varchar(50) ,
	postauthor varchar(50) ,
	postauthortotalposts int4 ,
	postauthoravatar varchar(255) ,
	postauthorwebsiteurl varchar(100) ,
	postauthorsignature varchar(255)
);
create or replace function mp_forumposts_selectallbythread
(
	int --:threadid $1
) returns setof mp_forumposts_selectallbythread_type 
as '
select	
		p.postid ,
		p.threadid ,
		p.threadsequence ,
		p.subject ,
		p.postdate ,
		p.approved ,
		p.userid ,
		p.sortorder ,
		p.post ,
		ft.forumid,
		coalesce(u.name,''guest'') as mostrecentpostuser,
		coalesce(s.name,''guest'') as startedby,
		coalesce(up.name, ''guest'') as postauthor,
		up.totalposts as postauthortotalposts,
		coalesce(up.avatarurl, ''blank.gif'') as postauthoravatar,
		up.websiteurl as postauthorwebsiteurl,
		up.signature as postauthorsignature
from		mp_forumposts p
join		mp_forumthreads ft
on		p.threadid = ft.threadid
left outer join		mp_users u
on		ft.mostrecentpostuserid = u.userid
left outer join		mp_users s
on		ft.startedbyuserid = s.userid
left outer join		mp_users up
on		up.userid = p.userid
where	ft.threadid = $1
		
order by	p.sortorder, p.postid desc; '
security definer language sql;
grant execute on function mp_forumposts_selectallbythread
(
	int --:threadid $1
) to public;

select drop_type('mp_forumposts_selectbythread_type');
CREATE TYPE public.mp_forumposts_selectbythread_type AS (
	postid int4 ,
	threadid int4 ,
	threadsequence int4 ,
	subject varchar(255) ,
	postdate timestamp ,
	approved bool ,
	userid int4 ,
	sortorder int4 ,
	post text,
	forumid int4 ,
	mostrecentpostuser varchar(50) ,
	startedby varchar(50) ,
	postauthor varchar(50) ,
	postauthortotalposts int4 ,
	postauthoravatar varchar(255) ,
	postauthorwebsiteurl varchar(100) ,
	postauthorsignature varchar(255)
);
create or replace function mp_forumposts_selectbythread
(
	int, --:threadid $1
	int --:pagenumber $2
) returns setof mp_forumposts_selectbythread_type 
as '
declare
	_threadid alias for $1;
	_pagenumber alias for $2;
	 _postsperpage	int;
	 _totalposts		int;
	 _currentpagemaxthreadsequence	int;
	 _beginsequence int;
	 _endsequence int;
	_rec mp_forumposts_selectbythread_type%ROWTYPE;

begin

select into _postsperpage, _totalposts 
	f.postsperpage, ft.totalreplies
from		mp_forumthreads ft
join		mp_forums f
on		ft.forumid = f.itemid
where	ft.threadid = _threadid;

_currentpagemaxthreadsequence := (_postsperpage * _pagenumber) ;

if _currentpagemaxthreadsequence > _postsperpage then
		_beginsequence := _currentpagemaxthreadsequence - _postsperpage + 1;
else
		_beginsequence := 1;
end if;

_endsequence := _beginsequence + _postsperpage  -1;

for _rec in
	select	
			p.postid ,
			p.threadid ,
			p.threadsequence ,
			p.subject ,
			p.postdate ,
			p.approved ,
			p.userid ,
			p.sortorder ,
			p.post ,
			ft.forumid,
			coalesce(u.name,''guest'') as mostrecentpostuser,
			coalesce(s.name,''guest'') as startedby,
			coalesce(up.name, ''guest'') as postauthor,
			up.totalposts as postauthortotalposts,
			coalesce(up.AvatarUrl, ''blank.gif'') as postauthoravatar,
			up.websiteurl as postauthorwebsiteurl,
			up.signature as postauthorsignature
	from		mp_forumposts p
	join		mp_forumthreads ft
	on		p.threadid = ft.threadid
	left outer join		mp_users u
	on		ft.mostrecentpostuserid = u.userid
	left outer join		mp_users s
	on		ft.startedbyuserid = s.userid
	left outer join		mp_users up
	on		up.userid = p.userid
	where	ft.threadid = _threadid
			and p.threadsequence >= _beginsequence
			and  p.threadsequence <= _endsequence
	order by	p.sortorder, p.postid   
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_forumposts_selectbythread
(
	int, --:threadid $1
	int --:pagenumber $2
) to public;



select drop_type('mp_forumposts_selectforrss_type');
CREATE TYPE public.mp_forumposts_selectforrss_type AS (
	postid int4 ,
	threadid int4 ,
	threadsequence int4 ,
	subject varchar(255) ,
	postdate timestamp ,
	approved bool ,
	userid int4 ,
	sortorder int4 ,
	post text,
	threadsubject varchar(255),
	forumid int4 ,
	startedby varchar(50) ,
	postauthor varchar(50) ,
	postauthortotalposts int4 ,
	postauthoravatar varchar(255) ,
	postauthorwebsiteurl varchar(100) ,
	postauthorsignature varchar(255)
);
create or replace function mp_forumposts_selectforrss
(
	int, --:siteid $1
	int, --:pageid $2
	int, --:moduleid $3
	int, --:itemid $4
	int, --:threadid $5
	int  --:maximumdays $6
) returns setof mp_forumposts_selectforrss_type 
as '
select		fp.postid ,
		fp.threadid,
		fp.threadsequence,
		fp.subject,
		fp.postdate,
		fp.approved,
		fp.userid,
		fp.sortorder,
		fp.post,
		ft.threadsubject,
		ft.forumid,
		coalesce(s.name, ''Guest'') as startedby,
		coalesce(up.name, ''Guest'') as postauthor,
		up.totalposts as postauthortotalposts,
		up.avatarurl as postauthoravatar,
		up.websiteurl as postauthorwebsiteurl,
		up.signature as postauthorsignature


from		mp_forumposts fp

join		mp_forumthreads ft
on		fp.threadid = ft.threadid

join		mp_forums f
on		ft.forumid = f.itemid

join		mp_modules m
on		f.moduleid = m.moduleid

join		mp_pagemodules pm
on		m.moduleid = pm.moduleid

join		mp_pages p
on		pm.pageid = p.pageid

left outer join		mp_users u
on		ft.mostrecentpostuserid = u.userid

left outer join		mp_users s
on		ft.startedbyuserid = s.userid

left outer join		mp_users up
on		up.userID = fp.userid

where	p.siteid = $1
and	($2 = -1 OR p.pageid = $2)
and	($3 = -1 OR m.moduleid = $3)
and	($4 = -1 OR f.itemid = $4)
and	($5 = -1 OR ft.threadid = $5)
and	($6 = -1 OR (current_timestamp(3) - fp.PostDate) <= (to_char($6, ''999999'') || ''days'')::interval)

order by	fp.PostDate desc;'
security definer language sql;
grant execute on function mp_forumposts_selectbythread
(
	int, --:threadid $1
	int --:pagenumber $2
) to public;




select drop_type('mp_forumposts_selectbythread_v2_type');
CREATE TYPE public.mp_forumposts_selectbythread_v2_type AS (
	postid int4 ,
	threadid int4 ,
	threadsequence int4 ,
	subject varchar(255) ,
	postdate timestamp ,
	approved bool ,
	userid int4 ,
	sortorder int4 ,
	post text,
	forumid int4 ,
	mostrecentpostuser varchar(50) ,
	startedby varchar(50) ,
	postauthor varchar(50) ,
	postauthortotalposts int4 ,
	postauthoravatar varchar(255) ,
	postauthorwebsiteurl varchar(100) ,
	postauthorsignature varchar(255)
);
create or replace function mp_forumposts_selectbythread_v2
(
	int, --:threadid $1
	int --:pagenumber $2
) returns setof mp_forumposts_selectbythread_v2_type 
as '
declare
	_threadid alias for $1;
	_pagenumber alias for $2;
	 _postsperpage	int;
	 _totalposts		int;
	 _currentpagemaxthreadsequence	int;
	 _beginsequence int;
	 _endsequence int;
	 _pagelowerbound int;
	 _pageupperbound int;
	_rec mp_forumposts_selectbythread_v2_type%ROWTYPE;

begin

select into _postsperpage, _totalposts 
		f.postsperpage, ft.totalreplies
from		mp_forumthreads ft
join		mp_forums f
on		ft.forumid = f.itemid
where	ft.threadid = _threadid;

_currentpagemaxthreadsequence := (_postsperpage * _pagenumber) ;

if (_currentpagemaxthreadsequence > _postsperpage) then
		_beginsequence := _currentpagemaxthreadsequence  - _postsperpage + 1;
else
		_beginsequence := 1;
end if;

_endsequence := _beginsequence + _postsperpage  -1;
--
--
-- set the page bounds
--_pagelowerbound := (_postsperpage * _pagenumber) ;
--_pageupperbound := _pagelowerbound + _postsperpage + 1;
-- create a temp table to store the select results

for _rec in
	select	
			p.postid ,
			p.threadid ,
			p.threadsequence ,
			p.subject ,
			p.postdate ,
			p.approved ,
			p.userid ,
			p.sortorder ,
			p.post ,
			ft.forumid,
			u.name as mostrecentpostuser,
			s.name as startedby,
			up.name as postauthor,
			up.totalposts as postauthortotalposts,
			up.avatarurl as postauthoravatar,
			up.websiteurl as postauthorwebsiteurl,
			up.signature as postauthorsignature
	from		mp_forumposts p
	join		mp_forumthreads ft
	on		p.threadid = ft.threadid
	join		mp_users u
	on		ft.mostrecentpostuserid = u.userid
	join		mp_users s
	on		ft.startedbyuserid = s.userid
	join		mp_users up
	on		up.userid = p.userid
	where	ft.threadid = _threadid
			and p.threadsequence >= _beginsequence
			and  p.threadsequence <= _endsequence
	order by	p.sortorder, p.postid
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_forumposts_selectbythread_v2
(
	int, --:threadid $1
	int --:pagenumber $2
) to public;

create or replace function mp_forumposts_selectone
(
	int --:postid $1
) returns setof mp_forumposts 
as '
select	fp.*
from		mp_forumposts fp
where	fp.postid = $1; '
security definer language sql;
grant execute on function mp_forumposts_selectone
(
	int --:postid $1
) to public;

create or replace function mp_forumposts_update
(
	int, --:postid $1
	varchar(255), --:subject $2
	text, --:post $3
	int, --:sortorder $4
	bool --:approved $5
) returns int4
as '
declare
	_postid alias for $1;
	_subject alias for $2;
	_post alias for $3;
	_sortorder alias for $4;
	_approved alias for $5;
	_rowcount int4;
begin

update		mp_forumposts
set			subject = _subject,
			post = _post,
			sortorder = _sortorder,
			approved = _approved
where		postid = _postid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumposts_update
(
	int, --:postid $1
	varchar(255), --:subject $2
	text, --:post $3
	int, --:sortorder $4
	bool --:approved $5
) to public;

select drop_type('mp_forumthreadsubscribers_selectbythread_type');
CREATE TYPE public.mp_forumthreadsubscribers_selectbythread_type AS (
		email varchar(100)
);
create or replace function mp_forumthreadsubscribers_selectbythread
(
	int, --:threadid $1
	int --:currentpostuserid $2
) returns setof mp_forumthreadsubscribers_selectbythread_type 
as '
select		u.email
from			mp_users u
join			mp_forumthreadsubscriptions s
on			u.userid = s.userid
where		s.threadid = $1
			and s.unsubscribedate is null
			and u.userid <> $2; '
security definer language sql;
grant execute on function mp_forumthreadsubscribers_selectbythread
(
	int, --:threadid $1
	int --:currentpostuserid $2
) to public;

create or replace function mp_forumthreadsubscriptions_insert
(
	int, --:threadid $1
	int --:userid $2
) returns int4 
as '
declare
	_threadid alias for $1;
	_userid alias for $2;
	t_found int;
	_rowcount int4;

begin

select into t_found 1 
from mp_forumthreadsubscriptions 
where 	threadid = _threadid and userid = _userid limit 1;

if  found then
	update 	mp_forumthreadsubscriptions
	set		subscribedate = current_timestamp(3),
			unsubscribedate = null
	
	where 	threadid = _threadid and userid = _userid;
else
	insert into	mp_forumthreadsubscriptions
	(
			threadid,
			userid
	)
	values
	(
			_threadid,
			_userid
	);   
end if;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreadsubscriptions_insert
(
	int, --:threadid $1
	int --:userid $2
) to public;

create or replace function mp_forumthreadsubscriptions_unsubscribeallthreads
(
	int --:userid $1
) returns int4 
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

update		mp_forumthreadsubscriptions
set			unsubscribedate = current_timestamp(3)
where		
			userid = _userid;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreadsubscriptions_unsubscribeallthreads
(
	int --:userid $1
) to public;

create or replace function mp_forumthreadsubscriptions_unsubscribethread
(
	int, --:threadid $1
	int --:userid $2
) returns int4
as '
declare
	_threadid alias for $1;
	_userid alias for $2;
	_rowcount int4;
begin

update		mp_forumthreadsubscriptions
set			unsubscribedate = current_timestamp(3)
where		threadid = _threadid
			and userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreadsubscriptions_unsubscribethread
(
	int, --:threadid $1
	int --:userid $2
) to public;

create or replace function mp_forumthreads_decrementreplycount
(
	int --:threadid $1
) returns int4
as '
declare
	_threadid alias for $1;
	 _mostrecentpostuserid int;
	 _mostrecentpostdate timestamp;
	_rowcount int4;
begin

select into _mostrecentpostuserid, _mostrecentpostdate
	userid, postdate
from mp_forumposts 
where threadid = _threadid 
order by postid desc limit 1;

update		mp_forumthreads
set			mostrecentpostuserid = _mostrecentpostuserid,
			totalreplies = totalreplies - 1,
			mostrecentpostdate = _mostrecentpostdate
where		threadid = _threadid;   
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_decrementreplycount
(
	int --:threadid $1
) to public;

create or replace function mp_forumthreads_delete
(
	int --:threadid $1
) returns int4
as '
declare
	_threadid alias for $1;
	_rowcount int4;
begin

	delete from  		mp_forumthreads
where		threadid = _threadid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_delete
(
	int --:threadid $1
) to public;

create or replace function mp_forumthreads_incrementreplycount
(
	int, --:threadid $1
	int, --:mostrecentpostuserid $2
	timestamp --:mostrecentpostdate $3
) returns int4
as '
declare
	_threadid alias for $1;
	_mostrecentpostuserid alias for $2;
	_mostrecentpostdate alias for $3;
	_rowcount int4;
begin

update		mp_forumthreads
set			mostrecentpostuserid = _mostrecentpostuserid,
			totalreplies = totalreplies + 1,
			mostrecentpostdate = _mostrecentpostdate
where		threadid = _threadid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_incrementreplycount
(
	int, --:threadid $1
	int, --:mostrecentpostuserid $2
	timestamp --:mostrecentpostdate $3
) to public;

create or replace function mp_forumthreads_insert
(
	int, --:forumid $1
	varchar(255), --:threadsubject $2
	int, --:sortorder $3
	bool, --:islocked $4
	int, --:startedbyuserid $5
	timestamp --:threaddate $6
) returns int4 
as '
declare
	_forumid alias for $1;
	_threadsubject alias for $2;
	_sortorder alias for $3;
	_islocked alias for $4;
	_startedbyuserid alias for $5;
	_threaddate alias for $6;
	 _forumsequence int;
	_itemid int;

begin

_forumsequence := (select coalesce(max(forumsequence) + 1,1) from mp_forumthreads where forumid = _forumid);

insert into		mp_forumthreads
(
			forumid,
			threadsubject,
			sortorder,
			forumsequence,
			islocked,
			startedbyuserid,
			threaddate,
			mostrecentpostuserid,
			mostrecentpostdate
)
values
(
			
			_forumid,
			_threadsubject,
			_sortorder,
			_forumsequence,
			_islocked,
			_startedbyuserid,
			_threaddate,
			_startedbyuserid,
			_threaddate
);

select into _itemid cast(currval(''mp_forumthreads_threadid_seq'') as int4);  

insert into mp_forumthreadsubscriptions (threadid, userid)
	select _itemid as threadid, userid from mp_forumsubscriptions fs 
		where fs.forumid = _forumid and fs.subscribedate is not null and fs.unsubscribedate is null;

return _itemid;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_insert
(
	int, --:forumid $1
	varchar(255), --:threadsubject $2
	int, --:sortorder $3
	bool, --:islocked $4
	int, --:startedbyuserid $5
	timestamp --:threaddate $6
) to public;

select drop_type('mp_forumthreads_selectbyforum_type');
CREATE TYPE public.mp_forumthreads_selectbyforum_type AS (
	threadid int4 ,
	forumid int4 ,
	threadsubject varchar(255) ,
	threaddate timestamp ,
	totalviews int4 ,
	totalreplies int4 ,
	sortorder int4 ,
	islocked bool ,
	forumsequence int4 ,
	mostrecentpostdate timestamp ,
	mostrecentpostuserid int4,
	startedbyuserid int4 ,
	mostrecentpostuser varchar(50),
	startedby varchar(50)
);
create or replace function mp_forumthreads_selectbyforum
(
	int, --:forumid $1
	int --:pagenumber $2
) returns setof mp_forumthreads_selectbyforum_type 
as '
declare
	_forumid alias for $1;
	_pagenumber alias for $2;
	 _threadsperpage	int;
	 _currentpagemaxforumsequence	int;
	 _beginsequence int;
	 _endsequence int;
	_rec mp_forumthreads_selectbyforum_type%ROWTYPE;

begin

select into _threadsperpage  threadsperpage
		
from		mp_forums
where	itemid = _forumid;

_currentpagemaxforumsequence := (_threadsperpage * _pagenumber);

if _currentpagemaxforumsequence > _threadsperpage + 1 then
		_beginsequence := _currentpagemaxforumsequence - _threadsperpage + 1;
else
		_beginsequence := 1;
end if;

_endsequence := _beginsequence + _threadsperpage  -1;

for _rec in
	select	
			t.threadid,
			forumid,
			threadsubject,
			threaddate,
			totalviews,
			totalreplies,
			sortorder,
			islocked,
			forumsequence,
			mostrecentpostdate,
			mostrecentpostuserid,
			startedbyuserid,
			coalesce(u.name, ''guest'') as mostrecentpostuser,
			s.name as startedby
	from		mp_forumthreads t
	left outer join		mp_users u
	on		t.mostrecentpostuserid = u.userid
	left outer join		mp_users s
	on		t.startedbyuserid = s.userid
	where	t.forumid = _forumid
			and t.forumsequence 
	between _beginsequence 
	and _endsequence
	order by	t.sortorder, t.threadid desc
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_selectbyforum
(
	int, --:forumid $1
	int --:pagenumber $2
) to public;

select drop_type('mp_forumthreads_selectbyforumdesc_type');
CREATE TYPE public.mp_forumthreads_selectbyforumdesc_type AS (
	threadid int4 ,
	forumid int4 ,
	threadsubject varchar(255) ,
	threaddate timestamp ,
	totalviews int4 ,
	totalreplies int4 ,
	sortorder int4 ,
	islocked bool ,
	forumsequence int4 ,
	mostrecentpostdate timestamp ,
	mostrecentpostuserid int4,
	startedbyuserid int4 ,
	mostrecentpostuser varchar(50),
	startedby varchar(50)
);
create or replace function mp_forumthreads_selectbyforumdesc
(
	int, --:forumid $1
	int --:pagenumber $2
) returns setof mp_forumthreads_selectbyforumdesc_type 
as '
declare
	_forumid alias for $1;
	_pagenumber alias for $2;
	 _threadsperpage	int;
	 _totalthreads	int;
	 _beginsequence int;
	 _endsequence int;
	_rec mp_forumthreads_selectbyforumdesc_type%ROWTYPE;

begin

select into _threadsperpage, _totalthreads 
		threadsperpage, _totalthreads
from		mp_forums
where	itemid = _forumid;

_beginsequence := _totalthreads - (_threadsperpage * _pagenumber) + 1;
_endsequence := _beginsequence + _threadsperpage  -1;

for _rec in
	select	
		t.threadid ,
		t.forumid ,
		t.threadsubject ,
		t.threaddate ,
		t.totalviews ,
		t.totalreplies ,
		t.sortorder ,
		t.islocked ,
		t.forumsequence ,
		t.mostrecentpostdate ,
		t.mostrecentpostuserid,
		startedbyuserid ,
		u.name as mostrecentpostuser ,
		s.name as startedby
	from		mp_forumthreads t
	left outer join		mp_users u
	on		t.mostrecentpostuserid = u.userid
	left outer join		mp_users s
	on		t.startedbyuserid = s.userid
	where	t.forumid = _forumid
			and t.forumsequence 
	between _beginsequence 
	and _endsequence
	order by	t.sortorder, t.threadid desc
	loop
		return next _rec;
	end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_selectbyforumdesc
(
	int, --:forumid $1
	int --:pagenumber $2
) to public;

select drop_type('mp_forumthreads_selectbyforumdesc_v2_type');
CREATE TYPE public.mp_forumthreads_selectbyforumdesc_v2_type AS (
	threadid int4 ,
	forumid int4 ,
	threadsubject varchar(255) ,
	threaddate timestamp ,
	totalviews int4 ,
	totalreplies int4 ,
	sortorder int4 ,
	islocked bool ,
	forumsequence int4 ,
	mostrecentpostdate timestamp ,
	mostrecentpostuserid int4,
	startedbyuserid int4 ,
	mostrecentpostuser varchar(50),
	startedby varchar(50)
);
create or replace function mp_forumthreads_selectbyforumdesc_v2
(
	int, --:forumid $1
	int --:pagenumber $2
) returns setof mp_forumthreads_selectbyforumdesc_v2_type 
as '
declare
	_forumid alias for $1;
	_pagenumber alias for $2;
	 _threadsperpage	int;
	 _totalthreads	int;
	 _beginsequence int;
	_rec mp_forumthreads_selectbyforumdesc_v2_type%ROWTYPE;

begin

select into _threadsperpage, _totalthreads 
		threadsperpage, threadcount 
from		mp_forums
where	itemid = _forumid;

_beginsequence := _totalthreads - (_threadsperpage * _pagenumber) + 1;
 
for _rec in
	select	
		t.threadid ,
		t.forumid ,
		t.threadsubject ,
		t.threaddate ,
		t.totalviews ,
		t.totalreplies ,
		t.sortorder ,
		t.islocked ,
		t.forumsequence ,
		t.mostrecentpostdate ,
		t.mostrecentpostuserid,
		startedbyuserid ,
		u.name as mostrecentpostuser ,
		s.name as startedby
	from		mp_forumthreads t
	left outer join		mp_users u
	on		t.mostrecentpostuserid = u.userid
	left outer join		mp_users s
	on		t.startedbyuserid = s.userid
	where	t.forumid = _forumid
	order by	t.mostrecentpostdate desc
	limit _threadsperpage
	offset _beginsequence
loop
		return next _rec;
	end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_selectbyforumdesc_v2
(
	int, --:forumid $1
	int --:pagenumber $2
) to public;

select drop_type('mp_forumthreads_selectone_type');
CREATE TYPE public.mp_forumthreads_selectone_type AS (
	threadid int4 ,
	forumid int4 ,
	threadsubject varchar(255) ,
	threaddate timestamp ,
	totalviews int4 ,
	totalreplies int4 ,
	sortorder int4 ,
	islocked bool ,
	forumsequence int4 ,
	mostrecentpostdate timestamp ,
	mostrecentpostuserid int4,
	startedbyuserid int4 ,
	mostrecentpostuser varchar(50),
	startedby varchar(50) ,
	postsperpage int4 
);
create or replace function mp_forumthreads_selectone
(
	int --:threadid $1
) returns setof mp_forumthreads_selectone_type 
as '
select	
		t.threadid ,
		t.forumid ,
		t.threadsubject ,
		t.threaddate ,
		t.totalviews ,
		t.totalreplies ,
		t.sortorder ,
		t.islocked ,
		t.forumsequence ,
		t.mostrecentpostdate ,
		t.mostrecentpostuserid,
		startedbyuserid ,
		coalesce(u.name, ''guest'') as mostrecentpostuser ,
		coalesce(s.name, ''guest'') as startedby ,
		f.postsperpage
from			mp_forumthreads t
left outer join	mp_users u
on			t.mostrecentpostuserid = u.userid
left outer join	mp_users s
on			t.startedbyuserid = s.userid
join			mp_forums f
on			f.itemid = t.forumid
where		t.threadid = $1; '
security definer language sql;
grant execute on function mp_forumthreads_selectone
(
	int --:threadid $1
) to public;

create or replace function mp_forumthreads_update
(
	int, --:threadid $1
	int, --:forumid $2
	varchar(255), --:threadsubject $3
	int, --:sortorder $4
	bool --:islocked $5
) returns int4
as '
declare
	_threadid alias for $1;
	_forumid alias for $2;
	_threadsubject alias for $3;
	_sortorder alias for $4;
	_islocked alias for $5;
	_rowcount int4;
begin

update		mp_forumthreads
set			forumid = _forumid,
			threadsubject = _threadsubject,
			sortorder = _sortorder,
			islocked = _islocked
where		threadid = _threadid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_update
(
	int, --:threadid $1
	int, --:forumid $2
	varchar(255), --:threadsubject $3
	int, --:sortorder $4
	bool --:islocked $5
) to public;

create or replace function mp_forumthreads_updateviewstats
(
	int --:threadid $1
) returns int4
as '
declare
	_threadid alias for $1;
	_rowcount int4;
begin

update		mp_forumthreads
set		
			totalviews = totalviews + 1
where		threadid = _threadid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumthreads_updateviewstats
(
	int --:threadid $1
) to public;

create or replace function mp_forums_decrementpostcount
(
	int --:forumid $1
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
begin

update mp_forums
set postcount = postcount - 1
where itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_decrementpostcount
(
	int --:forumid $1
) to public;

create or replace function mp_forums_decrementthreadcount
(
	int --:forumid $1
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
begin

update		mp_forums
set			threadcount = threadcount - 1
where		itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_decrementthreadcount
(
	int --:forumid $1
) to public;

create or replace function mp_forums_incrementpostcount
(
	int, --:forumid $1
	int, --:mostrecentpostuserid $2
	timestamp --:mostrecentpostdate $3
) returns int4
as '
declare
	_forumid alias for $1;
	_mostrecentpostuserid alias for $2;
	_mostrecentpostdate alias for $3;
	_rowcount int4;
begin

update 	mp_forums
set 		mostrecentpostdate = _mostrecentpostdate,
		mostrecentpostuserid = _mostrecentpostuserid,
 		postcount = postcount + 1
where 	itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_incrementpostcount
(
	int, --:forumid $1
	int, --:mostrecentpostuserid $2
	timestamp --:mostrecentpostdate $3
) to public;

-- 
create or replace function mp_forums_incrementpostcountonly
(
	int --:forumid $1
	
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
begin

update 	mp_forums
set 		
 		postcount = postcount + 1
where 	itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_incrementpostcountonly
(
	int --:forumid $1

) to public;

--

create or replace function mp_forums_incrementthreadcount
(
	int --:forumid $1
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
begin

update		mp_forums
set			threadcount = threadcount + 1
where		itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_incrementthreadcount
(
	int --:forumid $1
) to public;

create or replace function mp_forums_recalculatepoststats
(
	int --:forumid $1
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
	_mostrecentpostdate timestamp;
	_mostrecentpostuserid integer;
	_postcount integer;
begin
select into _mostrecentpostdate, _mostrecentpostuserid
        mostrecentpostdate, mostrecentpostuserid
    from mp_forumthreads 
    where forumid = _forumid
    order by mostrecentpostdate desc
    limit 1;
select into _postcount coalesce(sum(totalreplies), 0)+count(*)
    from mp_forumthreads 
    where forumid = _forumid;

update 	mp_forums
set 	mostrecentpostdate = _mostrecentpostdate,
		mostrecentpostuserid = coalesce(_mostrecentpostuserid, -1),
 		postcount = _postcount
where 	itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_recalculatepoststats
(
	int --:forumid $1
) to public;

create or replace function mp_forums_insert
(
	int, --:moduleid $1
	int, --:userid $2
	varchar(100), --:title $3
	text, --:description $4
	bool, --:ismoderated $5
	bool, --:isactive $6
	int, --:sortorder $7
	int, --:postsperpage $8
	int, --:threadsperpage $9
	bool --:allowanonymousposts $10
) returns int4 
as '
insert into			mp_forums
(
				moduleid,
				createdby,
				title,
				description,
				ismoderated,
				isactive,
				sortorder,
				postsperpage,
				threadsperpage,
				allowanonymousposts
)
values
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10
);
select cast(currval(''mp_forums_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_forums_insert
(
	int, --:moduleid $1
	int, --:userid $2
	varchar(100), --:title $3
	text, --:description $4
	bool, --:ismoderated $5
	bool, --:isactive $6
	int, --:sortorder $7
	int, --:postsperpage $8
	int, --:threadsperpage $9
	bool --:allowanonymousposts $10
) to public;

select drop_type('mp_forums_select_type');
CREATE TYPE public.mp_forums_select_type AS (
	itemid int4 ,
	moduleid int4 ,
	createddate timestamp ,
	createdby int4 ,
	title varchar(100) ,
	description text ,
	ismoderated bool ,
	isactive bool ,
	sortorder int4 ,
	threadcount int4 ,
	postcount int4 ,
	mostrecentpostdate timestamp,
	mostrecentpostuserid int4 ,
	postsperpage int4 ,
	threadsperpage int4 ,
	allowanonymousposts bool ,
	mostrecentpostuser varchar(50) ,
	subscribed bool
);
create or replace function mp_forums_select
(
	int, --:moduleid $1
	int --:userid $2
) returns setof mp_forums_select_type 
as '
select		
	f.itemid ,
	f.moduleid ,
	f.createddate ,
	f.createdby ,
	f.title ,
	f.description ,
	f.ismoderated ,
	f.isactive ,
	f.sortorder ,
	f.threadcount  ,
	f.postcount ,
	f.mostrecentpostdate,
	f.mostrecentpostuserid ,
	f.postsperpage ,
	f.threadsperpage ,
	f.allowanonymousposts ,
	u.name as mostrecentpostuser ,
	s.subscribedate is not null and s.unsubscribedate is null as subscribed
from			mp_forums f
left outer join	mp_users u
on			f.mostrecentpostuserid = u.userid
left outer join mp_forumsubscriptions s
on			f.itemid = s.forumid and s.userid = $2
where		f.moduleid	= $1
			and f.isactive = true
order by		f.sortorder, f.itemid; '
security definer language sql;
grant execute on function mp_forums_select
(
	int, --:moduleid $1
	int --:userid $1
) to public;

select drop_type('mp_forums_selectone_type');
CREATE TYPE public.mp_forums_selectone_type AS (
	itemid int4 ,
	moduleid int4 ,
	createddate timestamp ,
	createdby int4 ,
	title varchar(100) ,
	description text ,
	ismoderated bool ,
	isactive bool ,
	sortorder int4 ,
	threadcount int4 ,
	postcount int4 ,
	mostrecentpostdate timestamp,
	mostrecentpostuserid int4 ,
	postsperpage int4 ,
	threadsperpage int4 ,
	allowanonymousposts bool ,
	createdbyuser varchar(50) ,
	mostrecentpostuser varchar(50)
);
create or replace function mp_forums_selectone
(
	int --:itemid $1
) returns setof mp_forums_selectone_type 
as '
select		
	f.itemid ,
	f.moduleid ,
	f.createddate ,
	f.createdby ,
	f.title ,
	f.description ,
	f.ismoderated ,
	f.isactive ,
	f.sortorder ,
	f.threadcount  ,
	f.postcount ,
	f.mostrecentpostdate,
	f.mostrecentpostuserid ,
	f.postsperpage ,
	f.threadsperpage ,
	f.allowanonymousposts ,
	u.name as createdbyuser ,
	up.name as mostrecentpostuser
from			mp_forums f
left outer join	mp_users u
on			f.createdby = u.userid
left outer join	mp_users up
on			f.mostrecentpostuserid = up.userid
where		f.itemid = $1; '
security definer language sql;
grant execute on function mp_forums_selectone
(
	int --:itemid $1
) to public;


create or replace function mp_forums_update
(
	int, --:itemid $1
	varchar(100), --:title $2
	text, --:description $3
	bool, --:ismoderated $4
	bool, --:isactive $5
	int, --:sortorder $6
	int, --:postsperpage $7
	int, --:threadsperpage $8
	bool --:allowanonymousposts $9
) returns int4
as '
declare
	_itemid alias for $1;
	_title alias for $2;
	_description alias for $3;
	_ismoderated alias for $4;
	_isactive alias for $5;
	_sortorder alias for $6;
	_postsperpage alias for $7;
	_threadsperpage alias for $8;
	_allowanonymousposts alias for $9;
	_rowcount int4;
begin

update		mp_forums
set			title = _title,
			description = _description,
			ismoderated = _ismoderated,
			isactive = _isactive,
			sortorder = _sortorder,
			postsperpage = _postsperpage,
			threadsperpage = _threadsperpage,
			allowanonymousposts = _allowanonymousposts
where		itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_update
(
	int, --:itemid $1
	varchar(100), --:title $2
	text, --:description $3
	bool, --:ismoderated $4
	bool, --:isactive $5
	int, --:sortorder $6
	int, --:postsperpage $7
	int, --:threadsperpage $8
	bool --:allowanonymousposts $9
) to public;

create or replace function mp_forums_updatepoststats
(
	int, --:forumid $1
	int --:mostrecentpostuserid $2
) returns int4
as '
declare
	_forumid alias for $1;
	_mostrecentpostuserid alias for $2;
	_rowcount int4;
begin

update	mp_forums
set		mostrecentpostdate = current_timestamp(3),
		mostrecentpostuserid = _mostrecentpostuserid,
		postcount = postcount + 1
where	itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_updatepoststats
(
	int, --:forumid $1
	int --:mostrecentpostuserid $2
) to public;

create or replace function mp_forums_updatethreadstats
(
	int --:forumid $1
) returns int4
as '
declare
	_forumid alias for $1;
	_rowcount int4;
begin

update		mp_forums
set			threadcount = threadcount + 1
where		itemid = _forumid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forums_updatethreadstats
(
	int --:forumid $1
) to public;

create or replace function mp_forumsubscriptions_insert
(
	int, --:forumid $1
	int --:userid $2
) returns int4 
as '
declare
	_forumid alias for $1;
	_userid alias for $2;
	t_found int;
	_rowcount int4;

begin

select into t_found 1 
from mp_forumsubscriptions 
where 	forumid = _forumid and userid = _userid limit 1;

if  found then
	update 	mp_forumsubscriptions
	set		subscribedate = current_timestamp(3),
			unsubscribedate = null
	
	where 	forumid = _forumid and userid = _userid;
else
	insert into	mp_forumsubscriptions
	(
			forumid,
			userid
	)
	values
	(
			_forumid,
			_userid
	);   
end if;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumsubscriptions_insert
(
	int, --:forumid $1
	int --:userid $2
) to public;

create or replace function mp_forumsubscriptions_unsubscribe
(
	int, --:forumid $1
	int --:userid $2
) returns int4
as '
declare
	_forumid alias for $1;
	_userid alias for $2;
	_rowcount int4;
begin

update		mp_forumsubscriptions
set			unsubscribedate = current_timestamp(3)
where		forumid = _forumid
			and userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forumsubscriptions_unsubscribe
(
	int, --:forumid $1
	int --:userid $2
) to public;

create or replace function mp_galleryimages_delete
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from  mp_galleryimages
where
	itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_galleryimages_delete
(
	int --:itemid $1
) to public;

create or replace function mp_galleryimages_insert
(
	int, --:moduleid $1
	int, --:displayorder $2
	varchar(255), --:caption $3
	text, --:description $4
	text, --:metadataxml $5
	varchar(100), --:imagefile $6
	varchar(100), --:webimagefile $7
	varchar(100), --:thumbnailfile $8
	timestamp, --:uploaddate $9
	varchar(100) --:uploaduser $10
	
) returns int4 
as '
insert into 	mp_galleryimages
(
				moduleid,
				displayorder,
				caption,
				description,
				metadataxml,
				imagefile,
				webimagefile,
				thumbnailfile,
				uploaddate,
				uploaduser
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10
				
);
select cast(currval(''mp_galleryimages_itemid_seq'') as int4);; '
security definer language sql;
grant execute on function mp_galleryimages_insert
(
	int, --:moduleid $1
	int, --:displayorder $2
	varchar(255), --:caption $3
	text, --:description $4
	text, --:metadataxml $5
	varchar(100), --:imagefile $6
	varchar(100), --:webimagefile $7
	varchar(100), --:thumbnailfile $8
	timestamp, --:uploaddate $9
	varchar(100) --:uploaduser $10
	
) to public;

select drop_type('mp_galleryimages_select_type');
CREATE TYPE public.mp_galleryimages_select_type AS (

		itemid int4 ,
		moduleid int4 ,
		displayorder int4 ,
		caption varchar(255) ,
		description text ,
		metadataxml text ,
		imagefile varchar(100) ,
		webimagefile varchar(100) ,
		thumbnailfile varchar(100) ,
		uploaddate timestamp ,
		uploaduser varchar(100)
);
create or replace function mp_galleryimages_select
(
	int --:moduleid $1
) returns setof mp_galleryimages_select_type 
as '
select
		itemid,
		moduleid,
		displayorder,
		caption,
		description,
		metadataxml,
		imagefile,
		webimagefile,
		thumbnailfile,
		uploaddate,
		uploaduser
		
from
		mp_galleryimages
where	moduleid = $1; '
security definer language sql;
grant execute on function mp_galleryimages_select
(
	int --:moduleid $1
) to public;

select drop_type('mp_galleryimages_selectone_type');
CREATE TYPE public.mp_galleryimages_selectone_type AS (

		itemid int4 ,
		moduleid int4 ,
		displayorder int4 ,
		caption varchar(255) ,
		description text ,
		metadataxml text ,
		imagefile varchar(100) ,
		webimagefile varchar(100) ,
		thumbnailfile varchar(100) ,
		uploaddate timestamp ,
		uploaduser varchar(100) 
);
create or replace function mp_galleryimages_selectone
(
	int --:itemid $1
) returns setof mp_galleryimages_selectone_type 
as '
select
		itemid,
		moduleid,
		displayorder,
		caption,
		description,
		metadataxml,
		imagefile,
		webimagefile,
		thumbnailfile,
		uploaddate,
		uploaduser
		
from
		mp_galleryimages
		
where
		itemid = $1; '
security definer language sql;
grant execute on function mp_galleryimages_selectone
(
	int --:itemid $1
) to public;

select drop_type('mp_galleryimages_selectthumbsbypage_type');
CREATE TYPE public.mp_galleryimages_selectthumbsbypage_type AS (
	itemid int4,
	caption varchar(255),
	thumbnailfile varchar(100),
	webimagefile varchar(100),
	indexid int4,
	totalpages int4
);
create or replace function mp_galleryimages_selectthumbsbypage
(
	int, --:moduleid $1
	int, --:pagenumber $2
	int --:pagesize $3
) returns setof mp_galleryimages_selectthumbsbypage_type 
as '
declare
	_moduleid alias for $1;
	_pagenumber alias for $2;
	_pagesize alias for $3;
	 _pagelowerbound int;
	 _pageupperbound int;
	 _totalrows int;
	 _totalpages int;
	 _remainder int;
	_rec mp_galleryimages_selectthumbsbypage_type%ROWTYPE;
	p_index int;

begin

_pagelowerbound := (_pagesize * _pagenumber) - _pagesize;
_pageupperbound := _pagelowerbound + _pagesize + 1;

select into _totalrows  cast(count(*) as int4) 
from	mp_galleryimages t
where  t.moduleid = _moduleid;

_totalpages := _totalrows / _pagesize;

_remainder := _totalrows % _pagesize;

p_index := _pagelowerbound;

if _remainder > 0 then
	_totalpages := _totalpages + 1;
end if; 
for _rec in
	select	
		t.itemid,
		t.caption,
		t.thumbnailfile,
		t.webimagefile,
		p_index as indexid,
		_totalpages as totalpages
	from		mp_galleryimages t
	where	t.moduleid = _moduleid	
	order by	t.displayorder, t.itemid asc
	limit 	_pagesize
	offset _pagelowerbound
loop
	return next _rec;
	p_index := p_index + 1;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_galleryimages_selectthumbsbypage
(
	int, --:moduleid $1
	int, --:pagenumber $2
	int --:pagesize $3
) to public;






-- ---------------------------------------------------------------
select drop_type('mp_galleryimages_selectwebimagebypage_type');
CREATE TYPE public.mp_galleryimages_selectwebimagebypage_type AS (
	moduleid int4,
	itemid int4,
	totalpages int4
);

create or replace function mp_galleryimages_selectwebimagebypage
(
	int, --:moduleid $1
	int --:pagenumber $2
) returns setof mp_galleryimages_selectwebimagebypage_type 
as '
declare
	_moduleid alias for $1;
	_pagenumber alias for $2;
	 _pagesize 		int;
	 _pagelowerbound 	int;
	 _pageupperbound 	int;
	 _totalrows int;
	 _totalpages int;
	 _remainder int;
	_rec mp_galleryimages_selectwebimagebypage_type%ROWTYPE;
	p_index int;

begin

_pagesize := 1;
_pagelowerbound := (_pagesize * _pagenumber) - _pagesize;
_pageupperbound := _pagelowerbound + _pagesize + 1;

select into _totalrows  cast(count(*) as int4) 
from	mp_galleryimages t
where  t.moduleid = _moduleid;

_totalpages := _totalrows / _pagesize;
_remainder := _totalrows % _pagesize;

if _remainder > 0 then
	_totalpages := _totalpages + 1;
end if;

for _rec in
	select	t.moduleid,
		t.itemid,
            	_totalpages as totalpages
			
			
	from		mp_galleryimages t
	where	t.moduleid = _moduleid	
	order by	t.displayorder, t.itemid asc
    limit 	_pagesize
	offset _pagelowerbound
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_galleryimages_selectwebimagebypage
(
	int, --:moduleid $1
	int --:pagenumber $2
) to public;




-- --------------------------------------------------------------------
create or replace function mp_galleryimages_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:displayorder $3
	varchar(255),  --:caption $4
	text,  --:description $5
	text,  --:metadataxml $6
	varchar(100),  --:imagefile $7
	varchar(100),  --:webimagefile $8
	varchar(100),  --:thumbnailfile $9
	timestamp,  --:uploaddate $10
	varchar(100)  --:uploaduser $11
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_displayorder alias for $3;
	_caption alias for $4;
	_description alias for $5;
	_metadataxml alias for $6;
	_imagefile alias for $7;
	_webimagefile alias for $8;
	_thumbnailfile alias for $9;
	_uploaddate alias for $10;
	_uploaduser alias for $11;
	_rowcount int4;
begin

update 		mp_galleryimages 
set
			moduleid = _moduleid,
			displayorder = _displayorder,
			caption = _caption,
			description = _description,
			metadataxml = _metadataxml,
			imagefile = _imagefile,
			webimagefile = _webimagefile,
			thumbnailfile = _thumbnailfile,
			uploaddate = _uploaddate,
			uploaduser = _uploaduser
			
where
			itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_galleryimages_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:displayorder $3
	varchar(255),  --:caption $4
	text,  --:description $5
	text,  --:metadataxml $6
	varchar(100),  --:imagefile $7
	varchar(100),  --:webimagefile $8
	varchar(100),  --:thumbnailfile $9
	timestamp,  --:uploaddate $10
	varchar(100)  --:uploaduser $11
) to public;

create or replace function mp_htmlcontent_delete
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from  mp_htmlcontent
where
	itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_htmlcontent_delete
(
	int --:itemid $1
) to public;

create or replace function mp_htmlcontent_insert
(
	int, --:moduleid $1
	varchar(255), --:title $2
	text, --:excerpt $3
	text, --:body $4
	varchar(255), --:morelink $5
	int, --:sortorder $6
	timestamp, --:begindate $7
	timestamp, --:enddate $8
	timestamp, --:createddate $9
	int --:userid $10
	
) returns int4 
as '
insert into 	mp_htmlcontent 
(
				moduleid,
				title,
				excerpt,
				body,
				morelink,
				sortorder,
				begindate,
				enddate,
				createddate,
				userid
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10
				
);
select cast(currval(''mp_htmlcontent_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_htmlcontent_insert
(
	int, --:moduleid $1
	varchar(255), --:title $2
	text, --:excerpt $3
	text, --:body $4
	varchar(255), --:morelink $5
	int, --:sortorder $6
	timestamp, --:begindate $7
	timestamp, --:enddate $8
	timestamp, --:createddate $9
	int --:userid $10
	
) to public;

create or replace function mp_htmlcontent_select
(
	int, --:moduleid $1
	timestamp --:begindate $2
) returns setof mp_htmlcontent 
as '
select  	*
from		mp_htmlcontent
where	moduleid = $1
		and begindate <= $2
		and enddate >= $2; '
security definer language sql;
grant execute on function mp_htmlcontent_select
(
	int, --:moduleid $1
	timestamp --:begindate $2
) to public;

create or replace function mp_htmlcontent_selectall
(
) returns setof mp_htmlcontent 
as '
select	*
		
from
		mp_htmlcontent; '
security definer language sql;
grant execute on function mp_htmlcontent_selectall
(
) to public;

create or replace function mp_htmlcontent_selectone
(
	int --:itemid $1
) returns setof mp_htmlcontent 
as '
select  	*
from		mp_htmlcontent
where	itemid = $1; '
security definer language sql;
grant execute on function mp_htmlcontent_selectone
(
	int --:itemid $1
) to public;

create or replace function mp_htmlcontent_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	varchar(255),  --:title $3
	text,  --:excerpt $4
	text,  --:body $5
	varchar(255),  --:morelink $6
	int,  --:sortorder $7
	timestamp,  --:begindate $8
	timestamp,  --:enddate $9
	timestamp,  --:createddate $10
	int  --:userid $11
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_title alias for $3;
	_excerpt alias for $4;
	_body alias for $5;
	_morelink alias for $6;
	_sortorder alias for $7;
	_begindate alias for $8;
	_enddate alias for $9;
	_createddate alias for $10;
	_userid alias for $11;
	_rowcount int4;
begin

update 		mp_htmlcontent 
set
			moduleid = _moduleid,
			title = _title,
			excerpt = _excerpt,
			body = _body,
			morelink = _morelink,
			sortorder = _sortorder,
			begindate = _begindate,
			enddate = _enddate,
			createddate = _createddate,
			userid = _userid
			
where
			itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_htmlcontent_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	varchar(255),  --:title $3
	text,  --:excerpt $4
	text,  --:body $5
	varchar(255),  --:morelink $6
	int,  --:sortorder $7
	timestamp,  --:begindate $8
	timestamp,  --:enddate $9
	timestamp,  --:createddate $10
	int  --:userid $11
) to public;

create or replace function mp_links_delete
(
    
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_links
where
    itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_links_delete
(
    
	int --:itemid $1
) to public;

create or replace function mp_links_insert
(
	int, --:moduleid $1
	varchar(255), --:title $2
	varchar(255), --:url $3
	int, --:vieworder $4
	text, --:description $5
	timestamp, --:createddate $6
	int, --:createdby $7
	varchar(20) --:target $8
	
) returns int4 
as '
insert into 	mp_links 
(
				moduleid,
				title,
				url,
				vieworder,
				description,
				createddate,
				createdby,
				target
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8
				
);
select cast(currval(''mp_links_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_links_insert
(
	int, --:moduleid $1
	varchar(255), --:title $2
	varchar(255), --:url $3
	int, --:vieworder $4
	text, --:description $5
	timestamp, --:createddate $6
	int, --:createdby $7
	varchar(20) --:target $8
	
) to public;

create or replace function mp_links_select
(
	int --:moduleid $1
) returns setof mp_links 
as '
select	*
from
    mp_links
where
    moduleid = $1
order by
    vieworder, itemid; '
security definer language sql;
grant execute on function mp_links_select
( 
	int --:moduleid $1
) to public;

create or replace function mp_links_selectone
(
    
	int --:itemid $1
) returns setof mp_links 
as '
select
   *
from
    mp_links
where
    itemid = $1; '
security definer language sql;
grant execute on function mp_links_selectone
(
    
	int --:itemid $1
) to public;

create or replace function mp_links_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	varchar(255),  --:title $3
	varchar(255),  --:url $4
	int,  --:vieworder $5
	text,  --:description $6
	timestamp,  --:createddate $7
	int,  --:createdby $8
	varchar(20) --:target $9
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_title alias for $3;
	_url alias for $4;
	_vieworder alias for $5;
	_description alias for $6;
	_createddate alias for $7;
	_createdby alias for $8;
	_target alias for $9;
	_rowcount int4;
begin

update 		mp_links 
set
			moduleid = _moduleid,
			title = _title,
			url = _url,
			vieworder = _vieworder,
			description = _description,
			createddate = _createddate,
			createdby = _createdby,
			target = _target
			
where
			itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_links_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	varchar(255),  --:title $3
	varchar(255),  --:url $4
	int,  --:vieworder $5
	text,  --:description $6
	timestamp,  --:createddate $7
	int,  --:createdby $8
	varchar(20) --:target $9
) to public;

create or replace function mp_moduledefinitionsettings_select
(
	int --:moduledefid $1
) returns setof mp_moduledefinitionsettings 
as '
select
    *
from
    mp_moduledefinitionsettings
where
    moduledefid = $1; '
security definer language sql;
grant execute on function mp_moduledefinitionsettings_select
(
	int --:moduledefid $1
) to public;

create or replace function mp_moduledefinitionsettings_update
(
	int, --:moduledefid $1
	varchar(50), --:settingname $2
	varchar(255), --:settingvalue $3
	varchar(50), --:controltype $4
	text --:regexvalidationexpression $5
) returns int4 
as '
declare
	_moduledefid alias for $1;
	_settingname alias for $2;
	_settingvalue alias for $3;
	_controltype alias for $4;
	_regexvalidationexpression alias for $5;
	t_found int4;
	_rowcount int4;
begin

select into t_found 1 from 
        mp_moduledefinitionsettings 
    where 
        moduledefid = _moduledefid
      and
        settingname = _settingname limit 1;

if not found then
	insert into mp_moduledefinitionsettings (
	    moduledefid,
	    settingname,
	    settingvalue,
	    controltype,
	    regexvalidationexpression
	    
	) 
	values (
	    _moduledefid,
	    _settingname,
	    _settingvalue,
	    _controltype,
	    _regexvalidationexpression
	);
else
	update
	    mp_moduledefinitionsettings
	set
	    settingvalue = _settingvalue,
	    controltype = _controltype,
	    regexvalidationexpression = _regexvalidationexpression
	where
	    moduledefid = _moduledefid
	  and
	    settingname = _settingname;   
end if;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitionsettings_update
(
	int, --:moduledefid $1
	varchar(50), --:settingname $2
	varchar(255), --:settingvalue $3
	varchar(50), --:controltype $4
	text --:regexvalidationexpression $5
) to public;

-- added 5/24/2006 *******************************************

create or replace function mp_moduledefinitionsettings_updatebyid
(
	int, --:id $1
	int, --:moduledefid $2
	varchar(50), --:settingname $3
	varchar(255), --:settingvalue $4
	varchar(50), --:controltype $5
	text --:regexvalidationexpression $6
) returns int4 
as '
declare
	_id alias for $1;
	_moduledefid alias for $2;
	_settingname alias for $3;
	_settingvalue alias for $4;
	_controltype alias for $5;
	_regexvalidationexpression alias for $6;
	_rowcount int4;
begin


	update
	    mp_moduledefinitionsettings
	set
	    settingname = _settingname.
	    settingvalue = _settingvalue,
	    controltype = _controltype,
	    regexvalidationexpression = _regexvalidationexpression
	where
	    moduledefid = _moduledefid
	  and
	    id = _id;   

GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitionsettings_updatebyid
(
	int, --:id $1
	int, --:moduledefid $2
	varchar(50), --:settingname $3
	varchar(255), --:settingvalue $4
	varchar(50), --:controltype $5
	text --:regexvalidationexpression $6
) to public;




--

create or replace function mp_moduledefinitions_delete
(
    
	int --:moduledefid $1
) returns int4
as '
declare
	_moduledefid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_moduledefinitions
where
    moduledefid = _moduledefid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitions_delete
(
    
	int --:moduledefid $1
) to public;

-- added 5/24/2006

create or replace function mp_moduledefinitions_deletesettingbyid
(
    
	int --:id $1
) returns int4
as '
declare
	_id alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_moduledefinitionsettings
where
    id = _id; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitions_deletesettingbyid
(
    
	int --:id $1
) to public;



--


create or replace function mp_moduledefinitions_insert
(
	int, --:siteid $1
	varchar(255), --:featurename $2
	varchar(255), --:controlsrc $3
	int, --:sortorder $4
	bool, --:isadmin $5
	varchar(255), --:icon $6
	int --:defaultcachetime $7
	
) returns int4 
as '
declare
	_siteid alias for $1;
	_featurename alias for $2;
	_controlsrc alias for $3;
	_sortorder alias for $4;
	_isadmin alias for $5;
	_icon alias for $6;
	_defaultcachetime alias for $7;
	 _moduledefid int;

begin

insert into 	mp_moduledefinitions 
(
				featurename,
				controlsrc,
				sortorder,
				defaultcachetime,
				icon,
				isadmin
) 
values 
(
	
				_featurename,
				_controlsrc,
				_sortorder,
				_defaultcachetime,
				_icon,
				_isadmin
				
);

_moduledefid := cast(currval(''mp_moduledefinitions_moduledefid_seq'') as int4);
perform mp_sitemoduledefinitions_insert(_siteid, _moduledefid);
return _moduledefid;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitions_insert
(
	int, --:siteid $1
	varchar(255), --:featurename $2
	varchar(255), --:controlsrc $3
	int, --:sortorder $4
	bool, --:isadmin $5
	varchar(255), --:icon $6
	int --:defaultcachetime $7
	
) to public;

create or replace function mp_moduledefinitions_select
(
    
	int --:siteid $1
) returns setof mp_moduledefinitions
as '
select   	md.*
from		mp_moduledefinitions md
join		mp_sitemoduledefinitions smd
on		smd.moduledefid = md.moduledefid
    
where   	smd.siteid = $1
order by 	md.sortorder, md.featurename; '
security definer language sql;
grant execute on function mp_moduledefinitions_select
(
    
	int --:siteid $1
) to public;



create or replace function mp_moduledefinitions_selectone
(
    
	int --:moduledefid $1
) returns setof mp_moduledefinitions 
as '
select	*
from
    mp_moduledefinitions
where
    moduledefid = $1; '
security definer language sql;
grant execute on function mp_moduledefinitions_selectone
(
    
	int --:moduledefid $1
) to public;

create or replace function mp_moduledefinitions_selectusermodules
(
    
	int --:siteid $1
) returns setof mp_moduledefinitions
as '
select   		md.*
from			mp_moduledefinitions md
join			mp_sitemoduledefinitions smd
on			smd.moduledefid = md.moduledefid
    
where   		smd.siteid = $1
			and md.isadmin = false
order by 		md.sortorder, md.featurename; '
security definer language sql;
grant execute on function mp_moduledefinitions_selectusermodules
(
    
	int --:siteid $1
) to public;

create or replace function mp_moduledefinitions_update
(
	
	int,  --:moduledefid $1
	varchar(255),  --:featurename $2
	varchar(255),  --:controlsrc $3
	int,  --:sortorder $4
	bool,  --:isadmin $5
	varchar(255),  --:icon $6
	int  --:defaultcachetime $7
) returns int4
as '
declare
	_moduledefid alias for $1;
	_featurename alias for $2;
	_controlsrc alias for $3;
	_sortorder alias for $4;
	_isadmin alias for $5;
	_icon alias for $6;
	_defaultcachetime alias for $7;
	_rowcount int4;
begin

update 		mp_moduledefinitions 
set
			featurename = _featurename,
			controlsrc = _controlsrc,
			sortorder = _sortorder,
			defaultcachetime = _defaultcachetime,
			icon = _icon,
			isadmin = _isadmin
			
where
			moduledefid = _moduledefid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_moduledefinitions_update
(
	
	int,  --:moduledefid $1
	varchar(255),  --:featurename $2
	varchar(255),  --:controlsrc $3
	int,  --:sortorder $4
	bool,  --:isadmin $5
	varchar(255),  --:icon $6
	int  --:defaultcachetime $7
) to public;

create or replace function mp_modulesettings_createdefaultsettings
(
	int --:moduleid $1
) returns int4
as '
declare
	_moduleid alias for $1;
	_rowcount int4;
begin

insert into 	mp_modulesettings
(
			moduleid,
			settingname,
			settingvalue,
			controltype,
			regexvalidationexpression
)
select		m.moduleid,
			ds.settingname,
			ds.settingvalue,
			ds.controltype,
			ds.regexvalidationexpression
from			mp_modules m
join			mp_moduledefinitionsettings ds
on			ds.moduledefid = m.moduledefid
where		m.moduleid = _moduleid
order by		ds.id; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modulesettings_createdefaultsettings
(
	int --:moduleid $1
) to public;

create or replace function mp_modulesettings_delete
(
	int --:moduleid $1
) returns int4
as '
declare
	_moduleid alias for $1;
	_rowcount int4;
begin

	delete from  mp_modulesettings
where	moduleid = _moduleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modulesettings_delete
(
	int --:moduleid $1
) to public;

create or replace function mp_modulesettings_select
(
	int --:moduleid $1
) returns setof mp_modulesettings 
as '
select	*
from		mp_modulesettings
where	moduleid = $1; '
security definer language sql;
grant execute on function mp_modulesettings_select
(
	int --:moduleid $1
) to public;

-------------------------------------------


create or replace function mp_modulesettings_update
(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255) --:settingvalue $3
) returns int4 
as '
declare
	_moduleid alias for $1;
	_settingname alias for $2;
	_settingvalue alias for $3;
	t_found int4;
	_rowcount int4;
begin

select into t_found 1 from 
        mp_modulesettings 
    where 
        moduleid = _moduleid
      and
        settingname = _settingname limit 1;

if not found then
	insert into mp_modulesettings (
	    moduleid,
	    settingname,
	    settingvalue
	) 
	values (
	    _moduleid,
	    _settingname,
	    _settingvalue
	);
else
	update
	    mp_modulesettings
	set
	    settingvalue = _settingvalue
	where
	    moduleid = _moduleid
	  and
	    settingname = _settingname;   
end if;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modulesettings_update
(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255) --:settingvalue $3
) to public;



/* original
create or replace function mp_modulesettings_update
(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255) --:settingvalue $3
) returns int4 
as '
declare
	_moduleid alias for $1;
	_settingname alias for $2;
	_settingvalue alias for $3;
	t_found int4;
begin

select into t_found 1 from 
        mp_modulesettings 
    where 
        moduleid = _moduleid
      and
        settingname = _settingname limit 1;

if not found then
	insert into mp_modulesettings (
	    moduleid,
	    settingname,
	    settingvalue
	) 
	values (
	    _moduleid,
	    _settingname,
	    _settingvalue
	);
else
	update
	    mp_modulesettings
	set
	    settingvalue = _settingvalue
	where
	    moduleid = _moduleid
	  and
	    settingname = _settingname;   
end if;
return null;
end'
security definer language plpgsql;
grant execute on function mp_modulesettings_update
(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255) --:settingvalue $3
) to public;

*/

--------------------------------------------

create or replace function mp_modules_delete
(
	int --:moduleid $1
) returns int4
as '
declare
	_moduleid alias for $1;
	_rowcount int4;
begin

delete from  mp_pagemodules
where moduleid = _moduleid;

delete from  mp_modules
where moduleid = _moduleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modules_delete
(
	int --:moduleid $1
) to public;

-- added 5/24/2006 *******************************************

create or replace function mp_modules_deleteinstance
(
	int, --:moduleid $1
	int --:pageid $2
) returns int4
as '
declare
	_moduleid alias for $1;
	_pageid alias for $2;
	_rowcount int4;
begin

	delete from  mp_pagemodules
where moduleid = _moduleid and pageid = _pageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modules_deleteinstance
(
	int, --:moduleid $1
	int --:pageid $2
) to public;


create or replace function mp_pagemodule_exists
(
	int, --:moduleid $1
	int --:pageid $2
) returns int4
as '
select	cast(count(*) as int4)
from		mp_pagemodules
where	moduleid = $1 AND pageid = $2; '
security definer language sql;
grant execute on function mp_pagemodule_exists
(
	int, --:moduleid $1
	int --:pageid $2
) to public;


create or replace function mp_modules_countnonadmin
(
	int --:siteid $1
) returns int4
as '
select	cast(count(m.*) as int4)
from		mp_modules m
join		mp_moduledefinitions md
on		m.moduledefid = md.moduledefid
where	siteid = $1 AND md.isadmin = false; '
security definer language sql;
grant execute on function mp_modules_countnonadmin
(
	int --:siteid $1
) to public;



--

create or replace function mp_modules_insert
(
	int, --:siteid $1
	int, --:moduledefid $2
	varchar(255), --:moduletitle $3
	text, --:authorizededitroles $4
	int, --:cachetime $5
	bool, --:showtitle $6
	bool, --:availableformypage $7
	int, --:createdbyuserid $8
	timestamp, --:createddate $9
	bool, --:allowmultipleinstancesonmypage $10
	varchar(255) --:icon $11
) returns int4 
as '
insert into 	mp_modules 
(
				siteid,
				moduledefid,
				moduletitle,
				authorizededitroles,
				cachetime,
				showtitle,
				availableformypage,
				createdbyuserid,
				createddate,
				allowmultipleinstancesonmypage,
				icon
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10,
				$11
				
);
select cast(currval(''mp_modules_moduleid_seq'') as int4); '
security definer language sql;
grant execute on function mp_modules_insert
(
	int, --:siteid $1
	int, --:moduledefid $2
	varchar(255), --:moduletitle $3
	text, --:authorizededitroles $4
	int, --:cachetime $5
	bool, --:showtitle $6
	bool, --:availableformypage $7
	int, --:createdbyuserid $8
	timestamp, --:createddate $9
	bool, --:allowmultipleinstancesonmypage $10
	varchar(255) --:icon $11
) to public;

-- added 5/24/2006 
create or replace function mp_pagemodules_insert
(
int, --:pageid $1
int, --:moduleid $2
int, --:moduleorder $3
varchar(50), --:panename $4
timestamp, --:publishbegindate $5
timestamp --:publishenddate $6
) returns int4
as '
insert into mp_pagemodules(pageid, moduleid, moduleorder, panename, publishbegindate, publishenddate)
values ($1, $2, $3, $4, $5, $6);
--GET DIAGNOSTICS rowcount = ROW_COUNT;
select 1;
 '
security definer language sql;
grant execute on function mp_pagemodules_insert
(
int, --:pageid $1
int, --:moduleid $2
int, --:moduleorder $3
varchar(50), --:panename $4
timestamp, --:publishbegindate $5
timestamp --:publishenddate $6
) to public;

create or replace function mp_pagemodules_update
(
int, --:pageid $1
int, --:moduleid $2
int, --:moduleorder $3
varchar(50), --:panename $4
timestamp, --:publishbegindate $5
timestamp --:publishenddate $6
) returns int4
as '
update mp_pagemodules 
set
moduleorder = $3,
panename = $4,
publishbegindate = $5,
publishenddate = $6
where moduleid = $2 and pageid = $1;
--GET DIAGNOSTICS _rowcount = ROW_COUNT;
--return _rowcount;
select 1; '
security definer language sql;
grant execute on function mp_pagemodules_update
(
int, --:pageid $1
int, --:moduleid $2
int, --:moduleorder $3
varchar(50), --:panename $4
timestamp, --:publishbegindate $5
timestamp --:publishenddate $6
) to public;
create or replace function mp_modules_updatepage
(
	int, --:oldpageid $1
	int, --:newpageid $2
	int --:moduleid $3
) returns int4 
as '
update 	mp_pagemodules 
set
				
	pageid = $2
				
where moduleid = $3 and pageid = $1;
--GET DIAGNOSTICS _rowcount = ROW_COUNT;
--return _rowcount;
select 1; '
security definer language sql;
grant execute on function mp_modules_updatepage
(
	int, --:oldpageid $1
	int, --:newpageid $2
	int --:moduleid $3
	
) to public;




select drop_type('mp_modules_selectformypage_type');
CREATE TYPE public.mp_modules_selectformypage_type AS (
		moduleid int4 ,
		siteid int4 ,
		moduledefid int4 ,
		moduletitle varchar(255) ,
		allowmultipleinstancesonmypage bool,
		moduleicon varchar(255) ,
		featureicon varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_modules_selectformypage
(
	int --:siteid $1
) returns setof mp_modules_selectformypage_type 
as '
select  		
			m.moduleid ,
			m.siteid ,
			m.moduledefid ,
			m.moduletitle ,
			m.allowmultipleinstancesonmypage,
			m.icon as moduleicon,
			md.icon as featureicon,
			md.featurename
    
from
    			mp_modules m
  
inner join
    			mp_moduledefinitions md
on 			m.moduledefid = md.moduledefid
    
where   
    			m.siteid = $1 and m.availableformypage = true
		
    
order by
    			m.moduletitle; '
security definer language sql;
grant execute on function mp_modules_selectformypage
(
	int --:siteid $1
) to public;




-- end added 5/24/2006

select drop_type('mp_modules_selectbypage_type');
CREATE TYPE public.mp_modules_selectbypage_type AS (
		moduleid int4 ,
		pageid int4 ,
		moduledefid int4 ,
		moduleorder int4 ,
		panename varchar(50) ,
		moduletitle varchar(255) ,
		authorizededitroles text,
		cachetime int4 ,
		showtitle bool ,
		controlsrc varchar(255)
);

select drop_type('mp_modules_selectbypageid_type');
CREATE TYPE public.mp_modules_selectbypageid_type AS (
		moduleid int4 ,
		pageid int4 ,
		moduledefid int4 ,
		moduleorder int4 ,
		panename varchar(50) ,
		moduletitle varchar(255) ,
		authorizededitroles text,
		cachetime int4 ,
		showtitle bool ,
		controlsrc varchar(255),
		edituserid int4,
		availableformypage bool,
		createdbyuserid int4,
		createddate timestamp,
		publishbegindate timestamp,
		publishenddate timestamp
);

create or replace function mp_modules_selectbypageid
(
	int --:pageid $1
) returns setof mp_modules_selectbypageid_type 
as '
select  		
			m.moduleid ,
			pm.pageid ,
			m.moduledefid ,
			pm.moduleorder ,
			pm.panename ,
			m.moduletitle ,
			m.authorizededitroles ,
			m.cachetime ,
			m.showtitle ,
			md.controlsrc,
			m.edituserid,
			m.availableformypage,
			m.createdbyuserid,
			m.createddate,
			pm.publishbegindate,
			pm.publishenddate
    
from
    			mp_modules m
  
inner join
    			mp_moduledefinitions md
on 			m.moduledefid = md.moduledefid

inner join		mp_pagemodules pm
on			pm.moduleid = m.moduleid
    
where   
    			pm.pageid = $1
		
    
order by
    			pm.moduleorder; '
security definer language sql;
grant execute on function mp_modules_selectbypageid
(
	int --:pageid $1
) to public;

select drop_type('mp_modules_selectone_type');
CREATE TYPE public.mp_modules_selectone_type AS (
		moduleid int4 ,
		siteid int4 ,
		moduledefid int4 ,
		moduletitle varchar(255) ,
		icon varchar(255) ,
		authorizededitroles text,
		cachetime int4 ,
		showtitle bool ,
		edituserid int4,
		availableformypage boolean,
		allowmultipleinstancesonmypage boolean,
		countofuseonmypage int4 ,
		createdbyuserid int4,
		createddate timestamp
);



create or replace function mp_modules_selectone
(
	int --:moduleid $1
) returns setof mp_modules_selectone_type 
as '
select
         moduleid ,
         siteid ,
         moduledefid ,
         moduletitle ,
         icon,
         authorizededitroles ,
         cachetime ,
         showtitle ,
         edituserid,
         availableformypage,
         allowmultipleinstancesonmypage,
         countofuseonmypage,
         createdbyuserid,
         createddate
		
from
		mp_modules
		
where
		moduleid = $1; '
security definer language sql;
grant execute on function mp_modules_selectone
(
	int --:moduleid $1
) to public;

-- added 5/24/2006 ******************************

select drop_type('mp_modules_selectonebypage_type');
CREATE TYPE public.mp_modules_selectonebypage_type AS (
		moduleid int4 ,
		siteid int4,
		pageid int4 ,
		moduledefid int4 ,
		moduleorder int4 ,
		panename varchar(50) ,
		moduletitle varchar(255) ,
		authorizededitroles text,
		cachetime int4 ,
		showtitle bool ,
		edituserid int4,
		availableformypage boolean,
		allowmultipleinstancesonmypage boolean,
		countofuseonmypage int4 ,
		icon varchar(255) ,
		createdbyuserid int4,
		createddate timestamp,
		publishbegindate timestamp,
		publishenddate timestamp,
		controlsrc	varchar(255)
);



create or replace function mp_modules_selectonebypage
(
	int, --:moduleid $1
	int --:pageid $2
) returns setof mp_modules_selectonebypage_type 
as '
select
         m.moduleid ,
         m.siteid,
         pm.pageid ,
         m.moduledefid ,
         pm.moduleorder ,
         pm.panename ,
         m.moduletitle ,
         m.authorizededitroles ,
         m.cachetime ,
         m.showtitle ,
         m.edituserid,
         m.availableformypage,
         m.allowmultipleinstancesonmypage,
         m.countofuseonmypage,
         m.icon,
         m.createdbyuserid,
         m.createddate,
         pm.publishbegindate,
         pm.publishenddate,
         md.controlsrc
		
from
		mp_modules m
join		mp_moduledefinitions md
on		md.moduledefid = m.moduledefid

join		mp_pagemodules pm
on		m.moduleid = pm.moduleid
		
where		
		pm.moduleid = $1 AND pm.pageid = $2; '
security definer language sql;
grant execute on function mp_modules_selectonebypage
(
	int, --:moduleid $1
	int --:pageid $2
) to public;


-- end added 5/24/2006



create or replace function mp_modules_update
(
	int,  --:moduleid $1
	int,  --:moduledefid $2
	varchar(255),  --:moduletitle $3
	text,  --:authorizededitroles $4
	int,  --:cachetime $5
	bool,  --:showtitle $6
	int,  --:edituserid $7
	boolean,  --:availableformypage $8
	boolean,  --:allowmultipleinstancesonmypage $9
	varchar(255)  --:icon $10
) returns int4
as '
declare
	_moduleid alias for $1;
	_moduledefid alias for $2;
	_moduletitle alias for $3;
	_authorizededitroles alias for $4;
	_cachetime alias for $5;
	_showtitle alias for $6;
	_edituserid alias for $7;
	_availableformypage alias for $8;
	_allowmultipleinstancesonmypage alias for $9;
	_icon alias for $10;
	_rowcount int4;
begin

update 		mp_modules 
set
			
			moduledefid = _moduledefid,
			moduletitle = _moduletitle,
			authorizededitroles = _authorizededitroles,
			cachetime = _cachetime,
			showtitle = _showtitle,
			edituserid = _edituserid,
			availableformypage = _availableformypage,
			allowmultipleinstancesonmypage = _allowmultipleinstancesonmypage,
			icon = _icon
			
where
			moduleid = _moduleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modules_update
(
	
	int,  --:moduleid $1
	int,  --:moduledefid $2
	varchar(255),  --:moduletitle $3
	text,  --:authorizededitroles $4
	int,  --:cachetime $5
	bool,  --:showtitle $6
	int,  --:edituserid $7
	boolean,  --:availableformypage $8
	boolean,  --:allowmultipleinstancesonmypage $9
	varchar(255)  --:icon $10
) to public;

create or replace function mp_modules_updatemoduleorder
(
	int, --:pageid $1
	int, --:moduleid $2
	int, --:moduleorder $3
	varchar(50) --:panename $4
) returns int4
as '
declare
	_pageid alias for $1;
	_moduleid alias for $2;
	_moduleorder alias for $3;
	_panename alias for $4;
	_rowcount int4;
begin

update
    mp_pagemodules
set
    moduleorder = _moduleorder,
    panename    = _panename
where
    moduleid = _moduleid and pageid = _pageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modules_updatemoduleorder
(
	int, --:pageid $1
	int, --:moduleid $2
	int, --:moduleorder $3
	varchar(50) --:panename $4
) to public;








create or replace function mp_pages_delete
(
	int --:pageid $1
) returns int4
as '
declare
	_pageid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_pages
where
    pageid = _pageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_pages_delete
(
	int --:pageid $1
) to public;

select drop_type('mp_pages_getauthroles_type');
CREATE TYPE public.mp_pages_getauthroles_type AS (
  
	accessroles varchar(255) ,
	editroles varchar(255)
);
create or replace function mp_pages_getauthroles
(
	int, --:siteid $1
	int --:moduleid $2
) returns setof mp_pages_getauthroles_type 
as '
select  
	mp_pages.authorizedroles as accessroles ,
	mp_modules.authorizededitroles as editroles 
    
from    
    mp_modules
    inner join 
    mp_pagemodules on mp_pagemodules.moduleid = mp_modules.moduleid
  inner join
    mp_pages on mp_pagemodules.pageid = mp_pages.pageid
    
where   
    mp_modules.moduleid = $2
  and
    mp_pages.siteid = $1; '
security definer language sql;
grant execute on function mp_pages_getauthroles
(
	int, --:siteid $1
	int --:moduleid $2
) to public;

select drop_type('mp_pages_getbreadcrumbs_type');
CREATE TYPE public.mp_pages_getbreadcrumbs_type AS (
		pageid int4 ,
		pagename varchar(50) ,
		parent1id int4 ,
		parent1name varchar(50) ,
		parent2id int4 ,
		parent2name varchar(50) ,
		parent3id int4 ,
		parent3name varchar(50) ,
		parent4id int4 ,
		parent4name varchar(50) ,
		parent5id int4 ,
		parent5name varchar(50) ,
		parent6id int4 ,
		parent6name varchar(50) ,
		parent7id int4 ,
		parent7name varchar(50) ,
		parent8id int4 ,
		parent8name varchar(50) ,
		parent9id int4 ,
		parent9name varchar(50) ,
		parent10id int4 ,
		parent10name varchar(50) ,
		parent11id int4 ,
		parent11name varchar(50) ,
		parent12id int4 ,
		parent12name varchar(50) 
);
create or replace function mp_pages_getbreadcrumbs
(
	int --:pageid $1
) returns setof mp_pages_getbreadcrumbs_type 
as '
select		
			p.pageid,
			p.pagename,
			p.parentid as parent1id,
			p1.pagename as parent1name,
			coalesce(p1.parentid,-1) as parent2id,
			p2.pagename as parent2name,
			coalesce(p2.parentid,-1) as parent3id,
			p3.pagename as parent3name,
			coalesce(p3.parentid,-1) as parent4id,
			p4.pagename as parent4name,
			coalesce(p4.parentid,-1) as parent5id,
			p5.pagename as parent5name,
			coalesce(p5.parentid,-1) as parent6id,
			p6.pagename as parent6name,
			coalesce(p6.parentid,-1) as parent7id,
			p7.pagename as parent7name,
			coalesce(p7.parentid,-1) as parent8id,
			p8.pagename as parent8name,
			coalesce(p8.parentid,-1) as parent9id,
			p9.pagename as parent9name,
			coalesce(p9.parentid,-1) as parent10id,
			p10.pagename as parent10name,
			coalesce(p10.parentid,-1) as parent11id,
			p11.pagename as parent11name,
			coalesce(p11.parentid,-1) as parent12id,
			p12.pagename as parent12name
from			mp_pages p
left outer join	mp_pages p1
on			p1.pageid = p.parentid
left outer join	mp_pages p2
on			p2.pageid = p1.parentid
left outer join	mp_pages p3
on			p3.pageid = p2.parentid
left outer join	mp_pages p4
on			p4.pageid = p3.parentid
left outer join	mp_pages p5
on			p5.pageid = p4.parentid
left outer join	mp_pages p6
on			p6.pageid = p5.parentid
left outer join	mp_pages p7
on			p7.pageid = p6.parentid
left outer join	mp_pages p8
on			p8.pageid = p7.parentid
left outer join	mp_pages p9
on			p9.pageid = p8.parentid
left outer join	mp_pages p10
on			p10.pageid = p9.parentid
left outer join	mp_pages p11
on			p11.pageid = p10.parentid
left outer join	mp_pages p12
on			p12.pageid = p11.parentid
where 		p.pageid = $1; '
security definer language sql;
grant execute on function mp_pages_getbreadcrumbs
(
	int --:pageid $1
) to public;

create or replace function mp_pages_getnextpageorder
(
	int --:parentid $1
) returns int4
as '
select	coalesce(max(pageorder), -1) + 2
from		mp_pages
where	parentid = $1; '
security definer language sql;
grant execute on function mp_pages_getnextpageorder
(
	int --:parentid $1
) to public;




create or replace function mp_pages_insert
(
	int, --:siteid $1
	int, --:parentid $2
	varchar(50), --:pagename $3
	int, --:pageorder $4
	text, --:authorizedroles $5
	text, --:editroles $6
	text, --:createchildpageroles $7
	bool, --:requiressl $8
	bool, --:showbreadcrumbs $9
	bool, --:showchildbreadcrumbs $10
	varchar(255), --:pagekeywords $11
	varchar(255), --:pagedescription $12
	varchar(255), --:pageencoding $13
	varchar(255), --:additionalmetatags $14
	bool, --:useurl $15
	varchar(255), --:url $16
	bool, --:openinnewwindow $17
	bool, --:showchildpagemenu $18
	bool, --:hidemainmenu $19
	varchar(100), --:skin $20
	bool, --:includeinmenu $21
	varchar(50), --:menuimage $22
	varchar(255), --:pagetitle $23
	bool --:allowbrowsercache $24

) returns int4 
as '
insert into 		mp_pages
(
    			siteid,
			parentid,
    			pagename,
    			pageorder,
			authorizedroles,
			editroles,
			createchildpageroles,
    			requiressl,
    			showbreadcrumbs,
    			showchildbreadcrumbs,
    			pagekeywords,
			pagedescription,
			pageencoding,
			additionalmetatags,
			useurl,
			url,
			openinnewwindow,
			showchildpagemenu,
			hidemainmenu,
			skin,
			includeinmenu,
			menuimage,
			pagetitle,
			allowbrowsercache
)
values
(
    			$1,
			$2,
    			$3,
    			$4,
			$5,
    			$6,
    			$7,
			$8,
			$9,
			$10,
			$11,
			$12,
			$13,
			$14,
			$15,
			$16,
			$17,
			$18,
			$19,
			$20,
			$21,
			$22,
			$23,
			$24
);
select  cast(currval(''mp_pages_pageid_seq'') as int4); '
security definer language sql;
grant execute on function mp_pages_insert
(
	int, --:siteid $1
	int, --:parentid $2
	varchar(50), --:pagename $3
	int, --:pageorder $4
	text, --:authorizedroles $5
	text, --:editroles $6
	text, --:createchildpageroles $7
	bool, --:requiressl $8
	bool, --:showbreadcrumbs $9
	bool, --:showchildbreadcrumbs $10
	varchar(255), --:pagekeywords $11
	varchar(255), --:pagedescription $12
	varchar(255), --:pageencoding $13
	varchar(255), --:additionalmetatags $14
	bool, --:useurl $15
	varchar(255), --:url $16
	bool, --:openinnewwindow $17
	bool, --:showchildpagemenu $18
	bool, --:hidemainmenu $19
	varchar(100), --:skin $20
	bool, --:includeinmenu $21
	varchar(50), --:menuimage $22
	varchar(255), --:pagetitle $23
	bool --:allowbrowsercache $24
) to public;





-- ****

select drop_type('mp_pages_type');
CREATE TYPE public.mp_pages_type AS (
	pageid int4 ,
	parentid int4 ,
	pageorder int4 ,
	siteid int4 ,
	pagename varchar(50),
	pagetitle varchar(255),
	requiressl bool,
	allowbrowsercache bool,
	showbreadcrumbs bool,
	pagekeywords varchar(255),
	pagedescription varchar(255),
	pageencoding varchar(255),
	additionalmetatags varchar(255),
	menuimage varchar(50),
	useurl bool,
	url varchar(255),
	openinnewwindow bool,
	showchildpagemenu bool,
	authorizedroles text,
	editroles text,
	createchildpageroles text,
	showchildbreadcrumbs bool,
	hidemainmenu bool,
	skin varchar(100),
	includeinmenu bool
	
	
);



-- ***


create or replace function mp_pages_selectchildpages
(
	int --:parentid $1
) returns setof mp_pages_type 
as '
select	
		pageid ,
		parentid ,
		pageorder ,
		siteid ,
		pagename ,
		pagetitle,
		requiressl ,
		allowbrowsercache,
		showbreadcrumbs ,
		pagekeywords,
		pagedescription ,
		pageencoding ,
		additionalmetatags ,
		menuimage ,
		useurl ,
		url,
		openinnewwindow ,
		showchildpagemenu ,
		authorizedroles ,
		editroles ,
		createchildpageroles,
		showchildbreadcrumbs ,
		hidemainmenu,
		skin,
		includeinmenu
from		mp_pages
where	parentid = $1
order by pageorder; '
security definer language sql;
grant execute on function mp_pages_selectchildpages
(
	int --:parentid $1
) to public;



create or replace function mp_pages_selectlist
(
	int --:siteid $1
) returns setof mp_pages_type
as '
select  	pageid ,
		parentid ,
		pageorder ,
		siteid ,
		pagename ,
		pagetitle,
		requiressl ,
		allowbrowsercache,
		showbreadcrumbs ,
		pagekeywords,
		pagedescription ,
		pageencoding ,
		additionalmetatags ,
		menuimage ,
		useurl ,
		url,
		openinnewwindow ,
		showchildpagemenu ,
		authorizedroles ,
		editroles ,
		createchildpageroles,
		showchildbreadcrumbs ,
		hidemainmenu,
		skin,
		includeinmenu
    				
    
from    
    				mp_pages
    
where   
    				siteid = $1
order by			parentid,  pagename; '
security definer language sql;
grant execute on function mp_pages_selectlist
(
	int --:siteid $1
) to public;


create or replace function mp_pages_selectone
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_pages_type 
as '
select		pageid ,
		parentid ,
		pageorder ,
		siteid ,
		pagename ,
		pagetitle, 
		requiressl ,
		allowbrowsercache,
		showbreadcrumbs ,
		pagekeywords,
		pagedescription ,
		pageencoding ,
		additionalmetatags ,
		menuimage ,
		useurl ,
		url,
		openinnewwindow ,
		showchildpagemenu ,
		authorizedroles ,
		editroles ,
		createchildpageroles,
		showchildbreadcrumbs ,
		hidemainmenu,
		skin,
		includeinmenu
from		mp_pages

where	pageid = $2 or $2 = -1
order by parentid, pageorder
limit 1
; '
security definer language sql;
grant execute on function mp_pages_selectone
(
	int, --:siteid $1
	int --:pageid $2
) to public;










select drop_type('mp_pages_selecttree_type');
CREATE TYPE public.mp_pages_selecttree_type AS (
        pageid int,
        parentid int,
        pagename varchar (100),
        pagetitle varchar (255),
        pageorder int,
        nestlevel int,
        authorizedroles text,
        editroles text,
        createchildpageroles text
);

create or replace function mp_pages_selecttree
(
        
	int --:siteid $1
) returns setof mp_pages_selecttree_type 
as '
declare
	_siteid alias for $1;
	_lastlevel smallint;
	_rec mp_pages_selecttree_type%ROWTYPE;
	_rowcount int4;

begin

perform 1 from pg_class where
	  relname = ''t_pagetree'' and pg_table_is_visible(oid);
	if not found then
		create temp table t_pagetree
		(
			pageid int,
			pagename varchar (100),
			pagetitle varchar (255),
			parentid int,
			pageorder int,
			nestlevel int,
			treeorder varchar (1000)
		);
	end if;
  
_lastlevel := 0;

-- first, the parent levels
insert into     	t_pagetree
(
	pageid, 
	pagename, 
	pagetitle,
	parentid, 
	pageorder, 
	nestlevel, 
	treeorder
) 
select  		pageid,
			pagename,
			pagetitle,
			parentid,
			pageorder,
       			0,
        		(100000000 + pageorder)::text::varchar(20)
from   		mp_pages
where   		parentid is null  or parentid = -1
			and siteid = _siteid
order by 		pageorder;

get diagnostics _rowcount := row_count;

-- next, the children levels
while _rowcount > 0 loop

  _lastlevel := _lastlevel + 1;
  insert into     	t_pagetree
	(
		pageid, 
		pagename, 
		pagetitle,
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
	) 
                
    select  	p.pageid,
		repeat(''-'', _lastlevel *2) || p.pagename,
		p.pagetitle,
		p.parentid,
		p.pageorder,
		_lastlevel,
		cast(t.treeorder as varchar) || ''.'' || (100000000 + p.pageorder)::text::varchar
      from    	mp_pages p
 
      join 		t_pagetree t
      on 		p.parentid= t.pageid
      where   	exists (select ''x'' from t_pagetree where t_pagetree.pageid = p.parentid and nestlevel = _lastlevel - 1)
                 	and siteid = _siteid
      order by 	t.pageorder;

      get diagnostics _rowcount := row_count;

end loop;

--get the orphans
  insert into     	t_pagetree
		(
		pageid, 
		pagename, 
		pagetitle,
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
		) 
              
   select  	p.pageid,
		''(orphan)'' || p.pagename,
		p.pagetitle,
		p.parentid,
		p.pageorder,
		999999999,
		''999999999''
              
    from    	mp_pages p 
    where   	(select 1 from t_pagetree where pageid = p.pageid limit 1 ) is null
    and siteid  = _siteid;

-- reorder the pages by using a 2nd temp table and an identity field to keep them straight.

perform 1 from pg_class where
	  relname = ''t_pages_seq'' and pg_table_is_visible(oid);
	if not found then
		create temp sequence t_pages_seq
		    start -1
		    increment 2
		    maxvalue 9223372036854775807
		    minvalue -1
		    cache 1;
	end if;

perform setval(''t_pages_seq'', -1);

perform 1 from pg_class where
	  relname = ''t_pages'' and pg_table_is_visible(oid);
	if not found then
		create temp table t_pages
		(
			ord int default nextval(''t_pages_seq'') ,
			pageid varchar (100)
		);
	end if;

delete from t_pages;

insert into	t_pages (pageid)
select 		cast(pageid as varchar) as pageid 
from 		t_pagetree
order by 	nestlevel, treeorder;


-- change the taborder in the sirt temp table so that tabs are ordered in sequence
-- update 	t_pagetree
-- set 		pageorder = (select ord from t_pages where t_pages.pageid::text::int = t_pagetree.pageid);

--return temporary table

for _rec in
	select 	t.pageid, 
		t.parentid, 
		t.pagename, 
		t.pagetitle,
		t.pageorder, 
		t.nestlevel,
		p.authorizedroles,
		p.editroles,
		p.createchildpageroles
		
	from 		t_pagetree t
	join	mp_pages p
	on	t.pageid = p.pageid
	order by 	t.treeorder
loop
	return next _rec;
end loop;
delete from t_pages;
delete from t_pagetree;   
return;
end'
security definer language plpgsql;
grant execute on function mp_pages_selecttree
(
        
	int --:siteid $1
) to public;

-- added 5/24/2006

select drop_type('mp_pages_selecttreeformodule_type');
CREATE TYPE public.mp_pages_selecttreeformodule_type AS (
        pageid int,
        parentid int,
        pagename varchar (100),
        pageorder int,
        nestlevel int,
        authorizedroles text,
        editroles text,
        createchildpageroles text,
        ispublished int,
        panename varchar(50),
        moduleorder int,
        publishbegindate timestamp,
        publishenddate	timestamp
);

create or replace function mp_pages_selecttreeformodule
(
	int, --:siteid $1
	int --:moduleid $2
) returns setof mp_pages_selecttreeformodule_type 
as '
declare
	_siteid alias for $1;
	_moduleid alias for $2;
	_lastlevel smallint;
	_rec mp_pages_selecttreeformodule_type%ROWTYPE;
	_rowcount int4;

begin

perform 1 from pg_class where
	  relname = ''t_pagetree'' and pg_table_is_visible(oid);
	if not found then
		create temp table t_pagetree
		(
			pageid int,
			pagename varchar (100),
			parentid int,
			pageorder int,
			nestlevel int,
			treeorder varchar (1000)
		);
	end if;
  
_lastlevel := 0;

-- first, the parent levels
insert into     	t_pagetree
(
	pageid, 
	pagename, 
	parentid, 
	pageorder, 
	nestlevel, 
	treeorder
) 
select  		pageid,
			pagename,
			parentid,
			pageorder,
       			0,
        		(100000000 + pageorder)::text::varchar(20)
from   		mp_pages
where   		parentid is null  or parentid = -1
			and siteid = _siteid
order by 		pageorder;

get diagnostics _rowcount := row_count;

-- next, the children levels
while _rowcount > 0 loop

  _lastlevel := _lastlevel + 1;
  insert into     	t_pagetree
	(
		pageid, 
		pagename, 
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
	) 
                
    select  	p.pageid,
		repeat(''-'', _lastlevel *2) || p.pagename,
		p.parentid,
		p.pageorder,
		_lastlevel,
		cast(t.treeorder as varchar) || ''.'' || (100000000 + p.pageorder)::text::varchar
      from    	mp_pages p
 
      join 		t_pagetree t
      on 		p.parentid= t.pageid
      where   	exists (select ''x'' from t_pagetree where t_pagetree.pageid = p.parentid and nestlevel = _lastlevel - 1)
                 	and siteid = _siteid
      order by 	t.pageorder;

      get diagnostics _rowcount := row_count;

end loop;

--get the orphans
  insert into     	t_pagetree
		(
		pageid, 
		pagename, 
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
		) 
              
   select  	p.pageid,
		''(orphan)'' || p.pagename,
		p.parentid,
		p.pageorder,
		999999999,
		''999999999''
              
    from    	mp_pages p 
    where   	(select 1 from t_pagetree where pageid = p.pageid limit 1 ) is null
    and siteid  = _siteid;

-- reorder the pages by using a 2nd temp table and an identity field to keep them straight.

perform 1 from pg_class where
	  relname = ''t_pages_seq'' and pg_table_is_visible(oid);
	if not found then
		create temp sequence t_pages_seq
		    start -1
		    increment 2
		    maxvalue 9223372036854775807
		    minvalue -1
		    cache 1;
	end if;

perform setval(''t_pages_seq'', -1);

perform 1 from pg_class where
	  relname = ''t_pages'' and pg_table_is_visible(oid);
	if not found then
		create temp table t_pages
		(
			ord int default nextval(''t_pages_seq'') ,
			pageid varchar (100)
		);
	end if;

delete from t_pages;

insert into	t_pages (pageid)
select 		cast(pageid as varchar) as pageid 
from 		t_pagetree
order by 	nestlevel, treeorder;


-- change the taborder in the sirt temp table so that tabs are ordered in sequence
-- update 	t_pagetree
-- set 		pageorder = (select ord from t_pages where t_pages.pageid::text::int = t_pagetree.pageid);

--return temporary table

for _rec in
	select 	t.pageid, 
		t.parentid, 
		t.pagename, 
		t.pageorder, 
		t.nestlevel,
		p.authorizedroles,
		p.editroles,
		p.createchildpageroles,
		coalesce(pm.moduleid,-1) as ispublished,
		pm.panename,
		pm.moduleorder,
		pm.publishbegindate,
		pm.publishenddate
		
	from 		t_pagetree t
	join	mp_pages p
	on	t.pageid = p.pageid
	left outer join mp_pagemodules pm
	on pm.pageid = p.pageid AND pm.moduleid = _moduleid
	
	order by 	t.treeorder
loop
	return next _rec;
end loop;
delete from t_pages;
delete from t_pagetree;   
return;
end'
security definer language plpgsql;
grant execute on function mp_pages_selecttreeformodule
(
	int, --:siteid $1
	int --:moduleid $2
) to public;

-- end added5/24/2006


select drop_type('mp_pages_selecttree_dev_type');
CREATE TYPE public.mp_pages_selecttree_dev_type AS (
        pageid int,
        pagename varchar (100),
        parentid int,
        pageorder int,
        nestlevel int
);
/* todo
create or replace function mp_pages_selecttree_dev
(
        
	int --:siteid $1
) returns setof mp_pages_selecttree_dev_type 
as '
declare
	_siteid alias for $1;
	 _lastlevel smallint;
	_rec mp_pages_selecttree_dev_type%ROWTYPE;

begin

create table #pagetree
(
        pageid int,
        pagename varchar (100),
        parentid int,
        pageorder int,
        nestlevel int,
        treeorder varchar (1000)
)
  

_lastlevel := 0;
-- first, the parent levels
insert into     	#pagetree
select  		pageid,
        			pagename,
        			parentid,
        			pageorder,
       			0,
        			cast( 100000000 + pageorder as varchar(20) )
from   		mp_pages
where   		parentid is null  or parentid = -1
			and siteid = _siteid
order by 		pageorder
-- next, the children levels
while (@@rowcount > 0)
begin
  _lastlevel := _lastlevel + 1;
  insert        #pagetree 
	(
		pageid, 
		pagename, 
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
	) 
                
    select  	p.pageid,
                        	replicate(''-'', _lastlevel *2) + p.pagename,
                        	p.parentid,
                        	p.pageorder,
                        	_lastlevel,
                        	cast(t.treeorder as varchar) + ''.'' + cast(100000000 + p.pageorder as varchar)
      from    	mp_pages p
 
      join 		#pagetree t
      on 		p.parentid= t.pageid
      where   	exists (select ''x'' from #pagetree where pageid = p.parentid and nestlevel = _lastlevel - 1)
                 	and siteid = _siteid
      order by 	t.pageorder
end
--get the orphans
  insert        	#pagetree 
		(
		pageid, 
		pagename, 
		parentid, 
		pageorder, 
		nestlevel, 
		treeorder
		) 
                
   select  	p.pageid,
                        	''(orphan)'' + p.pagename,
                        	p.parentid,
                        	p.pageorder,
                        	999999999,
                        	''999999999''
                
    from    	mp_pages p 
    where   	not exists (select ''x'' from #pagetree where pageid = p.pageid)
                         	and siteid  = _siteid
-- reorder the pages by using a 2nd temp table and an identity field to keep them straight.
select 	identity(int,1,2) as ord , 
		cast(pageid as varchar) as pageid 
into 		#pages
from 		#pagetree
order by 	nestlevel, treeorder
-- change the taborder in the sirt temp table so that tabs are ordered in sequence
update 	#pagetree 
set 		pageorder = (select ord from #pages where cast(#pages.pageid as int) = #pagetree.pageid) 
-- return temporary table
select 	pageid, 
		parentid, 
		pagename, 
		pageorder, 
		nestlevel
from 		#pagetree 
order by 	treeorder
drop table #pages
drop table #pagetree;   return;
end'
security definer language plpgsql;
*/

create or replace function mp_pages_update
(
	int, --:siteid $1
	int, --:pageid $2
	int, --:parentid $3
	int, --:pageorder $4
	varchar(50), --:pagename $5
	text, --:authorizedroles $6
	text, --:editroles $7
	text, --:createchildpageroles $8
	bool, --:requiressl $9
	bool, --:showbreadcrumbs $10
	bool, --:showchildbreadcrumbs $11
	varchar(255), --:pagekeywords $12
	varchar(255), --:pagedescription $13
	varchar(255), --:pageencoding $14
	varchar(255), --:additionalmetatags $15
	bool, --:useurl $16
	varchar(255), --:url $17
	bool, --:openinnewwindow $18
	bool, --:showchildpagemenu $19
	bool, --:hidemainmenu $20
	varchar(100), --:skin $21
	bool, --:includeinmenu $22
	varchar(50), --:menuimage $23
	varchar(255), --:pagetitle $24
	bool --:allowbrowsercache $25
) returns int4 
as '
declare
	_siteid alias for $1;
	_pageid alias for $2;
	_parentid alias for $3;
	_pageorder alias for $4;
	_pagename alias for $5;
	_authorizedroles alias for $6;
	_editroles alias for $7;
	_createchildpageroles alias for $8;
	_requiressl alias for $9;
	_showbreadcrumbs alias for $10;
	_showchildbreadcrumbs alias for $11;
	_pagekeywords alias for $12;
	_pagedescription alias for $13;
	_pageencoding alias for $14;
	_additionalmetatags alias for $15;
	_useurl alias for $16;
	_url alias for $17;
	_openinnewwindow alias for $18;
	_showchildpagemenu alias for $19;
	_hidemainmenu alias for $20;
	_skin alias for $21;
	_includeinmenu alias for $22;
	_menuimage alias for $23;
	_pagetitle alias for $24;
	_allowbrowsercache alias for $25;
	t_found int4;
	_rowcount int4;
begin

select into t_found 1 from 
        mp_pages 
    where 
        pageid = _pageid limit 1;

if not found then

	insert into mp_pages
	(
		parentid,
		siteid,
		pageorder,
		pagename,
		pagetitle,
		authorizedroles,
		editroles,
		createchildpageroles,
		requiressl,
		allowbrowsercache,
		showbreadcrumbs,
		showchildbreadcrumbs,
		pagekeywords,
		pagedescription	,
		pageencoding,
		additionalmetatags,
		useurl,
		url,
		openinnewwindow,
		showchildpagemenu,
		hidemainmenu,
		skin,
		includeinmenu,
		menuimage
	) 
	values
	 (
		_parentid,
		_siteid,
		_pageorder,
		_pagename,
		_pagetitle,
		_authorizedroles,
		_editroles,
		_createchildpageroles,
		_requiressl,
		_allowbrowsercache,
		_showbreadcrumbs,
		_showchildbreadcrumbs,
		_pagekeywords,
		_pagedescription,
		_pageencoding,
		_additionalmetatags,
		_useurl,
		_url,
		_openinnewwindow,
		_showchildpagemenu,
		_hidemainmenu,
		_skin,
		_includeinmenu,
		_menuimage
	   
	);
else
	update
	    mp_pages
	set
		parentid = _parentid,
		pageorder = _pageorder,
		pagename = _pagename,
		pagetitle = _pagetitle,
		authorizedroles = _authorizedroles,
		editroles = _editroles,
		createchildpageroles = _createchildpageroles,
		requiressl = _requiressl,
		allowbrowsercache = _allowbrowsercache,
		showbreadcrumbs = _showbreadcrumbs,
		showchildbreadcrumbs = _showchildbreadcrumbs,
		pagekeywords = _pagekeywords,
		pagedescription = _pagedescription,
		pageencoding = _pageencoding,
		additionalmetatags = _additionalmetatags,
		useurl = _useurl,
		url = _url,
		openinnewwindow = _openinnewwindow,
		showchildpagemenu = _showchildpagemenu,
		hidemainmenu = _hidemainmenu,
		skin =_skin,
		includeinmenu = _includeinmenu,
		menuimage = _menuimage
	where
	    pageid = _pageid;   
end if;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_pages_update
(
	int, --:siteid $1
	int, --:pageid $2
	int, --:parentid $3
	int, --:pageorder $4
	varchar(50), --:pagename $5
	text, --:authorizedroles $6
	text, --:editroles $7
	text, --:createchildpageroles $8
	bool, --:requiressl $9
	bool, --:showbreadcrumbs $10
	bool, --:showchildbreadcrumbs $11
	varchar(255), --:pagekeywords $12
	varchar(255), --:pagedescription $13
	varchar(255), --:pageencoding $14
	varchar(255), --:additionalmetatags $15
	bool, --:useurl $16
	varchar(255), --:url $17
	bool, --:openinnewwindow $18
	bool, --:showchildmenupages $19
	bool, --:hidemainmenu $20
	varchar(100), --:skin $21
	bool, --:includeinmenu $22
	varchar(50), --:menuimage $23
	varchar(255), --:pagetitle $24
	bool --:allowbrowsercache $25
	
) to public;

create or replace function mp_pages_updatepageorder
(
	int, --:pageid $1
	int --:pageorder $2
) returns int4
as '
declare
	_pageid alias for $1;
	_pageorder alias for $2;
	_rowcount int4;
begin

update
    mp_pages
set
    pageorder = _pageorder
where
    pageid = _pageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_pages_updatepageorder
(
	int, --:pageid $1
	int --:pageorder $2
) to public;

create or replace function mp_roles_delete
(
	int --:roleid $1
) returns int4
as '
declare
	_roleid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_roles
where
    roleid = _roleid AND rolename <> ''Admins'' AND rolename <> ''Content Administrators'' AND rolename <> ''Authenticated Users'' ; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_roles_delete
(
	int --:roleid $1
) to public;




create or replace function mp_userroles_deleteuserroles
(
	int --:userid $1
) returns int4
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_userroles
where
    userid = _userid  ; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userroles_deleteuserroles
(
	int --:userid $1
) to public;





create or replace function mp_roles_insert
(
	int, --:siteid $1
	varchar(50) --:rolename $2
) returns int4 
as '
insert into mp_roles
(
    siteid,
    rolename,
    displayname
)
values
(
    $1,
    $2,
    $2
);
select  cast(currval(''mp_roles_roleid_seq'') as int4); '
security definer language sql;
grant execute on function mp_roles_insert
(
	int, --:siteid $1
	varchar(50) --:rolename $2
) to public;

select drop_type('mp_roles_select_type');
CREATE TYPE public.mp_roles_select_type AS (
    roleid int4 ,
    rolename varchar(50) ,
    displayname varchar(50)
    
);
create or replace function mp_roles_select
(
	int --:siteid $1
) returns setof mp_roles_select_type 
as '
select  
    roleid,
    rolename,
    displayname
    
from
    mp_roles
where   
    siteid = $1
order by roleid; '
security definer language sql;
grant execute on function mp_roles_select
(
	int --:siteid $1
) to public;




create or replace function mp_roles_selectone
(
	int --:roleid $1
) returns setof mp_roles 
as '
select
    *
from
    mp_roles
where
    roleid = $1; '
security definer language sql;
grant execute on function mp_roles_selectone
(
	int --:roleid $1
) to public;






create or replace function mp_roles_selectbyname
(
	int, --:siteid $1
	varchar(50) --:rolename $2
) returns setof mp_roles 
as '
select
    *
from
    mp_roles
where
    siteid = $1 AND rolename = $2; '
security definer language sql;
grant execute on function mp_roles_selectbyname
(
	int, --:siteid $1
	varchar(50) --:rolename $2
) to public;


create or replace function mp_roles_roleexists
(
	int, --:siteid $1
	varchar(50) --:rolename $2
) returns int4
as '
select	cast(count(*) as int4)
from		mp_roles
where	siteid = $1 AND rolename = $2; '
security definer language sql;
grant execute on function mp_roles_roleexists
(
	int, --:threadid $1
	varchar(50) --:rolename $2
) to public;





create or replace function mp_roles_update
(
	int, --:roleid $1
	varchar(50) --:diplayname $2
) returns int4
as '
declare
	_roleid alias for $1;
	_diplayname alias for $2;
	_rowcount int4;
begin

update
    mp_roles
set
    displayname = _diplayname
where
    roleid = _roleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_roles_update
(
	int, --:roleid $1
	varchar(50) --:displayname $2
) to public;

create or replace function mp_sharedfilefolders_delete
(
	int --:folderid $1
) returns int4
as '
declare
	_folderid alias for $1;
	_rowcount int4;
begin

	delete from  mp_sharedfilefolders
where
	folderid = _folderid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sharedfilefolders_delete
(
	int --:folderid $1
) to public;

create or replace function mp_sharedfilefolders_insert
(
	int, --:moduleid $1
	varchar(255), --:foldername $2
	int --:parentid $3
	
) returns int4 
as '
insert into 	mp_sharedfilefolders 
(
				moduleid,
				foldername,
				parentid
) 
values 
(
				$1,
				$2,
				$3
				
);
select cast(currval(''mp_sharedfilefolders_folderid_seq'') as int4); '
security definer language sql;
grant execute on function mp_sharedfilefolders_insert
(
	int, --:moduleid $1
	varchar(255), --:foldername $2
	int --:parentid $3
	
) to public;

select drop_type('mp_sharedfilefolders_selectallbymodule_type');
CREATE TYPE public.mp_sharedfilefolders_selectallbymodule_type AS (

		folderid int4 ,
		moduleid int4 ,
		foldername varchar(255) ,
		parentid int4
);
create or replace function mp_sharedfilefolders_selectallbymodule
(
	int --:moduleid $1
) returns setof mp_sharedfilefolders_selectallbymodule_type 
as '
select
		folderid,
		moduleid,
		foldername,
		parentid
		
from
		mp_sharedfilefolders
where	moduleid = $1; '
security definer language sql;
grant execute on function mp_sharedfilefolders_selectallbymodule
(
	int --:moduleid $1
) to public;

select drop_type('mp_sharedfilefolders_selectbymodule_type');
CREATE TYPE public.mp_sharedfilefolders_selectbymodule_type AS (

		folderid int4 ,
		foldername varchar(255) ,
		parentid int4
);
create or replace function mp_sharedfilefolders_selectbymodule
(
	int, --:moduleid $1
	int --:parentid $2
) returns setof mp_sharedfilefolders_selectbymodule_type 
as '
select
		folderid,
		foldername,
		parentid
		
from
		mp_sharedfilefolders
where	moduleid = $1
		and parentid = $2; '
security definer language sql;
grant execute on function mp_sharedfilefolders_selectbymodule
(
	int, --:moduleid $1
	int --:parentid $2
) to public;

select drop_type('mp_sharedfilefolders_selectone_type');
CREATE TYPE public.mp_sharedfilefolders_selectone_type AS (

		folderid int4 ,
		moduleid int4 ,
		foldername varchar(255) ,
		parentid int4
);
create or replace function mp_sharedfilefolders_selectone
(
	int --:folderid $1
) returns setof mp_sharedfilefolders_selectone_type 
as '
select
		folderid,
		moduleid,
		foldername,
		parentid
		
from
		mp_sharedfilefolders
		
where
		folderid = $1; '
security definer language sql;
grant execute on function mp_sharedfilefolders_selectone
(
	int --:folderid $1
) to public;

create or replace function mp_sharedfilefolders_update
(
	
	int,  --:folderid $1
	int, --:moduleid $2
	varchar(255),  --:foldername $3
	int  --:parentid $4
) returns int4
as '
declare
	_folderid alias for $1;
	_moduleid alias for $2;
	_foldername alias for $3;
	_parentid alias for $4;
	_rowcount int4;
begin

update 		mp_sharedfilefolders 
set
			moduleid = _moduleid,
			foldername = _foldername,
			parentid = _parentid
			
where
			folderid = _folderid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sharedfilefolders_update
(
	
	int,  --:folderid $1
	int, --:moduleid $2
	varchar(255),  --:foldername $3
	int  --:parentid $4
) to public;

create or replace function mp_sharedfileshistory_delete
(
	int --:id $1
) returns int4
as '
declare
	_id alias for $1;
	_rowcount int4;
begin

	delete from  mp_sharedfileshistory
where
	id = _id; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sharedfileshistory_delete
(
	int --:id $1
) to public;

create or replace function mp_sharedfileshistory_insert
(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(255), --:friendlyname $3
	varchar(255), --:originalfilename $4
	varchar(50), --:serverfilename $5
	int, --:sizeinkb $6
	timestamp, --:uploaddate $7
	int, --:uploaduserid $8
	timestamp --:archivedate $9
	
) returns int4 
as '
insert into 	mp_sharedfileshistory 
(
				itemid,
				moduleid,
				friendlyname,
				originalfilename,
				serverfilename,
				sizeinkb,
				uploaddate,
				uploaduserid,
				archivedate
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9
				
);
select cast(currval(''mp_sharedfileshistory_id_seq'') as int4); '
security definer language sql;
grant execute on function mp_sharedfileshistory_insert
(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(255), --:friendlyname $3
	varchar(255), --:originalfilename $4
	varchar(50), --:serverfilename $5
	int, --:sizeinkb $6
	timestamp, --:uploaddate $7
	int, --:uploaduserid $8
	timestamp --:archivedate $9
	
) to public;

select drop_type('mp_sharedfileshistory_select_type');
CREATE TYPE public.mp_sharedfileshistory_select_type AS (
		id int4 ,
		itemid int4 ,
		moduleid int4 ,
		friendlyname varchar(255) ,
		originalfilename varchar(255) ,
		serverfilename varchar(50) ,
		sizeinkb int4 ,
		uploaddate timestamp ,
		uploaduserid int4 ,
		archivedate timestamp ,
		name varchar(50)
);
create or replace function mp_sharedfileshistory_select
(
	int, --:moduleid $1
	int --:itemid $2
) returns setof mp_sharedfileshistory_select_type 
as '
select
		h.id,
		h.itemid,
		h.moduleid,
		h.friendlyname,
		h.originalfilename,
		h.serverfilename,
		h.sizeinkb,
		h.uploaddate,
		h.uploaduserid,
		h.archivedate,
		u.name
		
from
		mp_sharedfileshistory h
left outer join	mp_users u
on			u.userid = h.uploaduserid
where	h.moduleid = $1
		and h.itemid = $2
order by 	h.archivedate desc; '
security definer language sql;
grant execute on function mp_sharedfileshistory_select
(
	int, --:moduleid $1
	int --:itemid $2
) to public;

select drop_type('mp_sharedfileshistory_selectone_type');
CREATE TYPE public.mp_sharedfileshistory_selectone_type AS (
		id int4 ,
		itemid int4 ,
		moduleid int4 ,
		friendlyname varchar(255) ,
		originalfilename varchar(255) ,
		serverfilename varchar(50) ,
		sizeinkb int4 ,
		uploaddate timestamp ,
		uploaduserid int4 ,
		archivedate timestamp 
);
create or replace function mp_sharedfileshistory_selectone
(
	int --:id $1
) returns setof mp_sharedfileshistory_selectone_type 
as '
select
		id,
		itemid,
		moduleid,
		friendlyname,
		originalfilename,
		serverfilename,
		sizeinkb,
		uploaddate,
		uploaduserid,
		archivedate
		
from
		mp_sharedfileshistory
where	id = $1; '
security definer language sql;
grant execute on function mp_sharedfileshistory_selectone
(
	int --:id $1
) to public;

create or replace function mp_sharedfiles_delete
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from  mp_sharedfiles
where
	itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sharedfiles_delete
(
	int --:itemid $1
) to public;

create or replace function mp_sharedfiles_insert
(
	int, --:moduleid $1
	int, --:uploaduserid $2
	varchar(255), --:friendlyname $3
	varchar(255), --:originalfilename $4
	varchar(255), --:serverfilename $5
	int, --:sizeinkb $6
	timestamp, --:uploaddate $7
	int --:folderid $8
	
) returns int4 
as '
insert into 			mp_sharedfiles 
(
				moduleid,
				uploaduserid,
				friendlyname,
				originalfilename,
				serverfilename,
				sizeinkb,
				uploaddate,
				folderid
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8
				
);
select cast(currval(''mp_sharedfiles_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_sharedfiles_insert
(
	int, --:moduleid $1
	int, --:uploaduserid $2
	varchar(255), --:friendlyname $3
	varchar(255), --:originalfilename $4
	varchar(255), --:serverfilename $5
	int, --:sizeinkb $6
	timestamp, --:uploaddate $7
	int --:folderid $8
	
) to public;

select drop_type('mp_sharedfiles_selectbymodule_type');
CREATE TYPE public.mp_sharedfiles_selectbymodule_type AS (

		itemid int4 ,
		moduleid int4 ,
		uploaduserid int4 ,
		friendlyname varchar(255) ,
		originalfilename varchar(255),
		serverfilename varchar(255) ,
		sizeinkb int4 ,
		uploaddate timestamp ,
		folderid int4,
		username varchar(100)
);
create or replace function mp_sharedfiles_selectbymodule
(
	int, --:moduleid $1
	int --:folderid $2
) returns setof mp_sharedfiles_selectbymodule_type 
as '
select
		sf.itemid,
		sf.moduleid,
		sf.uploaduserid,
		sf.friendlyname,
		sf.originalfilename,
		sf.serverfilename,
		sf.sizeinkb,
		sf.uploaddate,
		sf.folderid,
		u.name as username
		
from
		mp_sharedfiles sf
left outer join
		mp_users u
on		sf.uploaduserid = u.userid
		
where	sf.moduleid = $1
		and sf.folderid = $2; '
security definer language sql;
grant execute on function mp_sharedfiles_selectbymodule
(
	int, --:moduleid $1
	int --:folderid $2
) to public;

select drop_type('mp_sharedfiles_selectone_type');
CREATE TYPE public.mp_sharedfiles_selectone_type AS (

		itemid int4 ,
		moduleid int4 ,
		uploaduserid int4 ,
		friendlyname varchar(255) ,
		originalfilename varchar(255) ,
		serverfilename varchar(255) ,
		sizeinkb int4 ,
		uploaddate timestamp ,
		folderid int4
);
create or replace function mp_sharedfiles_selectone
(
	int --:itemid $1
) returns setof mp_sharedfiles_selectone_type 
as '
select
		itemid,
		moduleid,
		uploaduserid,
		friendlyname,
		originalfilename,
		serverfilename,
		sizeinkb,
		uploaddate,
		folderid
		
from
		mp_sharedfiles
		
where
		itemid = $1; '
security definer language sql;
grant execute on function mp_sharedfiles_selectone
(
	int --:itemid $1
) to public;

create or replace function mp_sharedfiles_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:uploaduserid $3
	varchar(255),  --:friendlyname $4
	varchar(255),  --:originalfilename $5
	varchar(255),  --:serverfilename $6
	int,  --:sizeinkb $7
	timestamp,  --:uploaddate $8
	int  --:folderid $9
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_uploaduserid alias for $3;
	_friendlyname alias for $4;
	_originalfilename alias for $5;
	_serverfilename alias for $6;
	_sizeinkb alias for $7;
	_uploaddate alias for $8;
	_folderid alias for $9;
	_rowcount int4;
begin

update 		mp_sharedfiles 
set
			moduleid = _moduleid,
			uploaduserid = _uploaduserid,
			friendlyname = _friendlyname,
			originalfilename = _originalfilename,
			serverfilename = _serverfilename,
			sizeinkb = _sizeinkb,
			uploaddate = _uploaddate,
			folderid = _folderid
			
where
			itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sharedfiles_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:uploaduserid $3
	varchar(255),  --:friendlyname $4
	varchar(255),  --:originalfilename $5
	varchar(255),  --:serverfilename $6
	int,  --:sizeinkb $7
	timestamp,  --:uploaddate $8
	int  --:folderid $9
) to public;

create or replace function mp_sitehosts_delete
(
	int --:hostid $1
) returns int4
as '
declare
	_hostid alias for $1;
	_rowcount int4;
begin

	delete from  mp_sitehosts
where
	hostid = _hostid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitehosts_delete
(
	int --:hostid $1
) to public;

create or replace function mp_sitehosts_insert
(
	int, --:siteid $1
	varchar(255) --:hostname $2
	
) returns int4 
as '
insert into 	mp_sitehosts 
(
				siteid,
				hostname
) 
values 
(
				$1,
				$2
				
);
select cast(currval(''mp_sitehosts_hostid_seq'') as int4);; '
security definer language sql;
grant execute on function mp_sitehosts_insert
(
	int, --:siteid $1
	varchar(255) --:hostname $2
	
) to public;

select drop_type('mp_sitehosts_select_type');
CREATE TYPE public.mp_sitehosts_select_type AS (

		hostid int4 ,
		siteid int4 ,
		hostname varchar(255)
);
create or replace function mp_sitehosts_select
(
	int --:siteid $1
) returns setof mp_sitehosts_select_type 
as '
select
		hostid,
		siteid,
		hostname
		
from
		mp_sitehosts
where	siteid = $1; '
security definer language sql;
grant execute on function mp_sitehosts_select
(
	int --:siteid $1
) to public;

select drop_type('mp_sitehosts_selectone_type');
CREATE TYPE public.mp_sitehosts_selectone_type AS (

		hostid int4 ,
		siteid int4 ,
		hostname varchar(255)
);
create or replace function mp_sitehosts_selectone
(
	int --:hostid $1
) returns setof mp_sitehosts_selectone_type 
as '
select
		hostid,
		siteid,
		hostname
		
from
		mp_sitehosts
		
where
		hostid = $1; '
security definer language sql;
grant execute on function mp_sitehosts_selectone
(
	int --:hostid $1
) to public;

create or replace function mp_sitehosts_update
(
	
	int,  --:hostid $1
	int,  --:siteid $2
	varchar(255)  --:hostname $3
) returns int4
as '
declare
	_hostid alias for $1;
	_siteid alias for $2;
	_hostname alias for $3;
	_rowcount int4;
begin

update 		mp_sitehosts 
set
			siteid = _siteid,
			hostname = _hostname
			
where
			hostid = _hostid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitehosts_update
(
	
	int,  --:hostid $1
	int,  --:siteid $2
	varchar(255)  --:hostname $3
) to public;

create or replace function mp_sitemoduledefinitions_delete
(
	int, --:siteid $1
	int --:moduledefid $2
) returns int4
as '
declare
	_siteid alias for $1;
	_moduledefid alias for $2;
	_rowcount int4;
begin

	delete from  mp_sitemoduledefinitions
where	siteid = _siteid 
		and moduledefid = _moduledefid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitemoduledefinitions_delete
(
	int, --:siteid $1
	int --:moduledefid $2
) to public;

create or replace function mp_sitemoduledefinitions_insert
(
	int, --:siteid $1
	int --:moduledefid $2
) returns int4 
as '
declare
	_siteid alias for $1;
	_moduledefid alias for $2;
	t_found int;
	_rowcount int4;

begin

_rowcount := 0;
select into t_found 1 from mp_sitemoduledefinitions where siteid = _siteid and moduledefid = _moduledefid limit 1;
if not found then
	insert into mp_sitemoduledefinitions (siteid, moduledefid)
	values	(_siteid, _moduledefid);   
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
end if;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitemoduledefinitions_insert
(
	int, --:siteid $1
	int --:moduledefid $2
) to public;



select drop_type('mp_sitesettings_getpagelist_type');
CREATE TYPE public.mp_sitesettings_getpagelist_type AS (
	pageid int4 ,
	parentid int4 ,
	pageorder int4 ,
	siteid int4 ,
	pagename varchar(50),
	menuimage varchar(50),
	requiressl bool,
	showbreadcrumbs bool,
	pagekeywords varchar(255),
	pagedescription varchar(255),
	pageencoding varchar(255),
	additionalmetatags varchar(255),
	useurl bool,
	url varchar(255),
	openinnewwindow bool,
	showchildpagemenu bool,
	authorizedroles text,
	editroles text,
	createchildpageroles text,
	showchildbreadcrumbs bool,
	hidemainmenu bool,
	skin varchar(100)
	
	
);







create or replace function mp_sitesettings_getpagelist
(
	int --:siteid $1
) returns setof mp_sitesettings_getpagelist_type
as '
select  
    		pageid ,
		parentid ,
		pageorder ,
		siteid ,
		pagename ,
		menuimage,
		requiressl ,
		showbreadcrumbs ,
		pagekeywords,
		pagedescription ,
		pageencoding ,
		additionalmetatags ,
		useurl ,
		url,
		openinnewwindow ,
		showchildpagemenu ,
		authorizedroles ,
		editroles ,
		createchildpageroles,
		showchildbreadcrumbs ,
		hidemainmenu,
		skin 
    
from    
    				mp_pages
    
where   
    				siteid = $1 and includeinmenu = true
order by			parentid, pageorder, pagename; '
security definer language sql;
grant execute on function mp_sitesettings_getpagelist
(
	int --:siteid $1
) to public;




/*
create or replace function mp_sitesettings_getpagelist
(
	int --:siteid $1
) returns setof mp_pages
as '
select  *
from    mp_pages
    
where   siteid = $1
order by parentid, pageorder, pagename; '
security definer language sql;
grant execute on function mp_sitesettings_getpagelist
(
	int --:siteid $1
) to public;

*/

select drop_type('mp_sitesettings_selectdefaultpage_type');
CREATE TYPE public.mp_sitesettings_selectdefaultpage_type AS (
	siteid int4 ,
	sitename varchar(255) ,
	skin varchar(100) ,
	editorskin varchar(50) ,
	logo varchar(50) ,
	icon varchar(50) ,
	allownewregistration bool ,
	allowuserskins bool ,
	allowpageskins bool ,
	allowhidemenuonpages bool ,
	defaultfriendlyurlpatternenum varchar(50),
	usesecureregistration bool ,
	enablemypagefeature bool ,
	usesslonallpages bool ,
	metakeywords varchar(255) ,
	metadescription varchar(255),
	metaencoding varchar(255),
	metaadditional varchar(255),
	pagemetakeywords varchar(255) ,
	pagemetadescription varchar(255) ,
	pagemetaencoding varchar(255) ,
	pagemetaadditional varchar(255) ,
	isserveradminsite bool ,
	useldapauth bool ,
	autocreateldapuseronfirstlogin bool,
	ldapserver varchar(255) ,
	ldapport int4 ,
	ldapdomain varchar(255) ,
	ldaprootdn varchar(255) ,
	ldapuserdnkey varchar(10) ,
	allowuserfullnamechange bool ,
	useemailforlogin bool ,
	reallydeleteusers bool,
	pageid int4 ,
	parentid int4 ,
	pageorder int4 ,
	pagename varchar(50) ,
	menuimage varchar(50) ,
	requiressl bool ,
	authorizedroles text ,
	editroles text,
	createchildpageroles text,
	showbreadcrumbs bool,
	showchildbreadcrumbs bool,
	showchildpagemenu bool,
	hidemainmenu bool ,
	pageskin varchar(100)
);
create or replace function mp_sitesettings_selectdefaultpage
(
	varchar(255) --:hostname $1
) returns setof mp_sitesettings_selectdefaultpage_type 
as '

 select 
        		s.siteid,
         		s.sitename,
			s.skin,
			s.editorskin,
			s.logo,
			s.icon,
			s.allownewregistration,
			s.allowuserskins,
			s.allowpageskins,
			s.allowhidemenuonpages,
			s.defaultfriendlyurlpatternenum,
			s.usesecureregistration,
			s.enablemypagefeature,
			s.usesslonallpages,
			coalesce(s.defaultpagekeywords,  '''') as metakeywords,
			coalesce(s.defaultpagedescription,  '''') as metadescription,
			coalesce(s.defaultpageencoding,  '''') as metaencoding,
			coalesce(s.defaultadditionalmetatags,  '''') as metaadditional,
			coalesce(p.pagekeywords, '''') as pagemetakeywords,
			coalesce(p.pagedescription, '''') as pagemetadescription,
			coalesce(p.pageencoding, '''') as pagemetaencoding,
			coalesce(p.additionalmetatags, '''') as pagemetaadditional,
			s.isserveradminsite,
			s.useldapauth,
			s.autocreateldapuseronfirstlogin,
			s.ldapserver,
			s.ldapport,
			s.ldapdomain,
			s.ldaprootdn,
			s.ldapuserdnkey,
			s.allowuserfullnamechange,
			s.useemailforlogin,
			s.reallydeleteusers,
        		p.pageid,
			p.parentid,
         		p.pageorder,
        		p.pagename,
        		p.menuimage,
         		p.requiressl,
        		p.authorizedroles,
        		p.editroles,
 			p.createchildpageroles,
        		p.showbreadcrumbs,
        		p.showchildbreadcrumbs,
        		p.showchildpagemenu,
        		p.hidemainmenu,
			p.skin as pageskin
from			mp_pages p
    
inner join		mp_sites  s
on 			p.siteid = s.siteid
        
    
where
        			s.siteid = coalesce(
				(select siteid from mp_sitehosts where hostname = $1 limit 1),
				 (select siteid from mp_sites order by siteid limit 1)
				)
        
order by
        			p.parentid, p.pageorder
limit 1; '
security definer language sql;
grant execute on function mp_sitesettings_selectdefaultpage
(
	varchar(255) --:hostname $1
) to public;

select drop_type('mp_sitesettings_selectdefaultpagebyid_type');
CREATE TYPE public.mp_sitesettings_selectdefaultpagebyid_type AS (
	siteid int4 ,
	sitename varchar(255) ,
	skin varchar(100) ,
	editorskin varchar(50) ,
	logo varchar(50) ,
	icon varchar(50) ,
	allownewregistration bool ,
	allowuserskins bool ,
	allowpageskins bool ,
	allowhidemenuonpages bool ,
	defaultfriendlyurlpatternenum varchar(50),
	usesecureregistration bool ,
	enablemypagefeature bool ,
	usesslonallpages bool ,
	metakeywords varchar(255) ,
	metadescription varchar(255),
	metaencoding varchar(255),
	metaadditional varchar(255),
	pagemetakeywords varchar(255) ,
	pagemetadescription varchar(255) ,
	pagemetaencoding varchar(255) ,
	pagemetaadditional varchar(255) ,
	isserveradminsite bool ,
	useldapauth bool ,
	autocreateldapuseronfirstlogin bool ,
	ldapserver varchar(255) ,
	ldapport int4 ,
	ldapdomain varchar(255) ,
	ldaprootdn varchar(255) ,
	ldapuserdnkey varchar(10) ,
	allowuserfullnamechange bool ,
	useemailforlogin bool ,
	reallydeleteusers bool,
	pageid int4 ,
	parentid int4 ,
	pageorder int4 ,
	pagename varchar(50) ,
	menuimage varchar(50) ,
	requiressl bool ,
	authorizedroles text ,
	editroles text,
	createchildpageroles text,
	showbreadcrumbs bool,
	showchildbreadcrumbs bool,
	showchildpagemenu bool,
	hidemainmenu bool ,
	pageskin varchar(100)
);
create or replace function mp_sitesettings_selectdefaultpagebyid
(
	int --:siteid $1
) returns setof mp_sitesettings_selectdefaultpagebyid_type 
as '
 select 
			s.siteid,
			s.sitename,
			s.skin,
			s.editorskin,
			s.logo,
			s.icon,
			s.allownewregistration,
			s.allowuserskins,
			s.allowpageskins,
			s.allowhidemenuonpages,
			s.defaultfriendlyurlpatternenum,
			s.usesecureregistration,
			s.enablemypagefeature,
			s.usesslonallpages,
			coalesce(s.defaultpagekeywords,  '''') as metakeywords ,
			coalesce(s.defaultpagedescription,  '''') as metadescription ,
			coalesce(s.defaultpageencoding,  '''') as metaencoding ,
			coalesce(s.defaultadditionalmetatags,  '''') as metaadditional ,
			coalesce(p.pagekeywords, '''') as pagemetakeywords ,
			coalesce(p.pagedescription, '''') as pagemetadescription ,
			coalesce(p.pageencoding, '''') as pagemetaencoding ,
			coalesce(p.additionalmetatags, '''') as pagemetaadditional ,
			s.isserveradminsite,
			s.useldapauth,
			s.autocreateldapuseronfirstlogin,
			s.ldapserver,
			s.ldapport,
			s.ldapdomain,
			s.ldaprootdn,
			s.ldapuserdnkey,
			s.allowuserfullnamechange,
			s.useemailforlogin,
			s.reallydeleteusers,
			p.pageid,
			p.parentid,
			p.pageorder,
			p.pagename,
			p.menuimage,
			p.requiressl,
			p.authorizedroles,
			p.editroles,
 			p.createchildpageroles,
			p.showbreadcrumbs,
			p.showchildbreadcrumbs,
			p.showchildpagemenu,
			p.hidemainmenu,
			p.skin as pageskin
from			mp_pages p
    
inner join		mp_sites  s
on 			p.siteid = s.siteid
        
    
where
        			s.siteid = $1
        
order by
        			p.parentid, p.pageorder
limit 1; '
security definer language sql;
grant execute on function mp_sitesettings_selectdefaultpagebyid
(
	int --:siteid $1
) to public;

select drop_type('mp_sitesettings_selectpage_type');
CREATE TYPE public.mp_sitesettings_selectpage_type AS (
	siteid int4 ,
	sitename varchar(255) ,
	skin varchar(100) ,
	editorskin varchar(50) ,
	logo varchar(50) ,
	icon varchar(50) ,
	allownewregistration bool ,
	allowuserskins bool ,
	allowpageskins bool ,
	allowhidemenuonpages bool ,
	defaultfriendlyurlpatternenum varchar(50),
	usesecureregistration bool ,
	enablemypagefeature bool ,
	usesslonallpages bool ,
	metakeywords varchar(255) ,
	metadescription varchar(255),
	metaencoding varchar(255),
	metaadditional varchar(255),
	pagemetakeywords varchar(255) ,
	pagemetadescription varchar(255) ,
	pagemetaencoding varchar(255) ,
	pagemetaadditional varchar(255) ,
	isserveradminsite bool ,
	useldapauth bool ,
	autocreateldapuseronfirstlogin bool ,
	ldapserver varchar(255) ,
	ldapport int4 ,
	ldapdomain varchar(255) ,
	ldaprootdn varchar(255) ,
	ldapuserdnkey varchar(10) ,
	allowuserfullnamechange bool ,
	useemailforlogin bool ,
	reallydeleteusers bool,
	pageid int4 ,
	parentid int4 ,
	pageorder int4 ,
	pagename varchar(50) ,
	menuimage varchar(50) ,
	requiressl bool ,
	authorizedroles text ,
	editroles text,
	createchildpageroles text,
	showbreadcrumbs bool,
	showchildbreadcrumbs bool,
	showchildpagemenu bool,
	hidemainmenu bool ,
	pageskin varchar(100)
);
create or replace function mp_sitesettings_selectpage
(
	int, --:pageid $1
	varchar(255) --:hostname $2
) returns setof mp_sitesettings_selectpage_type 
as '
 select
			s.siteid,
			s.sitename,
			s.skin,
			s.editorskin,
			s.logo,
			s.icon,
			s.allownewregistration,
			s.allowuserskins,
			s.allowpageskins,
			s.allowhidemenuonpages,
			s.defaultfriendlyurlpatternenum,
			s.usesecureregistration,
			s.enablemypagefeature,
			s.usesslonallpages,
			coalesce(s.defaultpagekeywords,  '''') as metakeywords ,
			coalesce(s.defaultpagedescription,  '''') as metadescription ,
			coalesce(s.defaultpageencoding,  '''') as metaencoding ,
			coalesce(s.defaultadditionalmetatags,  '''') as metaadditional ,
			coalesce(p.pagekeywords, '''') as pagemetakeywords ,
			coalesce(p.pagedescription, '''') as pagemetadescription ,
			coalesce(p.pageencoding, '''') as pagemetaencoding ,
			coalesce(p.additionalmetatags, '''') as pagemetaadditional ,
			s.isserveradminsite,
			s.useldapauth,
			s.autocreateldapuseronfirstlogin,
			s.ldapserver,
			s.ldapport,
			s.ldapdomain,
			s.ldaprootdn,
			s.ldapuserdnkey,
			s.allowuserfullnamechange,
			s.useemailforlogin,
			s.reallydeleteusers,
			p.pageid,
			p.parentid,
			p.pageorder,
			p.pagename,
			p.menuimage,
			p.requiressl,
			p.authorizedroles,
			p.editroles,
 			p.createchildpageroles,
			p.showbreadcrumbs,
			p.showchildbreadcrumbs,
			p.showchildpagemenu,
			p.hidemainmenu,
			p.skin as pageskin
from			mp_pages p
    
inner join		mp_sites  s
on 			p.siteid = s.siteid
        
    
where		s.siteid = coalesce(	(select siteid from mp_sitehosts where hostname = $2 limit 1),
				 (select siteid from mp_sites order by siteid limit 1)
			)
        			and p.pageid = $1
        
order by
        			p.pageorder
limit 1;  '
security definer language sql;
grant execute on function mp_sitesettings_selectpage
(
	int, --:pageid $1
	varchar(255) --:hostname $2
) to public;


create or replace function mp_sites_count
(
) returns int4 
as '
select cast(count(*) as int4) from mp_sites; '
security definer language sql;
grant execute on function mp_sites_count
(
) to public;

create or replace function mp_sites_delete
(
	int --:siteid $1
) returns int4
as '
declare
	_siteid alias for $1;
	_rowcount int4;
begin

	delete from  mp_sites
where
	siteid = _siteid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sites_delete
(
	int --:siteid $1
) to public;








create or replace function mp_sites_insert
(
	varchar(255), --:sitename $1
	varchar(100), --:skin $2
	varchar(50), --:logo $3
	varchar(50), --:icon $4
	bool, --:allowuserskins $5
	bool, --:allownewregistration $6
	bool, --:usesecureregistration $7
	bool, --:enablemypagefeature $8
	bool, --:usesslonallpages $9
	varchar(255), --:defaultpagekeywords $10
	varchar(255), --:defaultpagedescription $11
	varchar(255), --:defaultpageencoding $12
	varchar(255), --:defaultadditionalmetatags $13
	bool, --:isserveradminsite $14
	bool, --:allowpageskins $15
	bool, --:allowhidemenuonpages $16
	bool, --:useldapauth $17
	bool, --:autocreateldapuseronfirstlogin $18
	varchar(255), --:ldapserver $19
	int4, --:ldapport $20
	varchar(255), --:ldaprootdn $21
	varchar(10), --:ldapuserdnkey $22
	bool, --:allowuserfullnamechange $23
	bool, --:useemailforlogin $24
	bool, --:reallydeleteusers $25
	varchar(50), --:editorskin $26
	varchar(50), --:defaultfriendlyurlpatternenum $27
	varchar(36), --:siteguid $28
	varchar(255) --:ldapdomain $29
	
) returns int4 
as '
insert into 	mp_sites 
(
				
				sitename,
				skin,
				logo,
				icon,
				allowuserskins,
				allownewregistration,
				usesecureregistration,
				enablemypagefeature,
				usesslonallpages,
				defaultpagekeywords,
				defaultpagedescription,
				defaultpageencoding,
				defaultadditionalmetatags,
				isserveradminsite,
				allowpageskins,
				allowhidemenuonpages,
				useldapauth,
				autocreateldapuseronfirstlogin,
				ldapserver,
				ldapport,
				ldaprootdn,
				ldapuserdnkey,
				allowuserfullnamechange,
				useemailforlogin,
				reallydeleteusers,
				editorskin,
				defaultfriendlyurlpatternenum,
				siteguid,
				ldapdomain
) 
values 
(
				
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10,
				$11,
				$12,
				$13,
				$14,
				$15,
				$16,
				$17,
				$18,
				$19,
				$20,
				$21,
				$22,
				$23,
				$24,
				$25,
				$26,
				$27,
				$28,
				$29
				
				
);
select cast(currval(''mp_sites_siteid_seq'') as int4); '
security definer language sql;
grant execute on function mp_sites_insert
(
	varchar(255), --:sitename $1
	varchar(100), --:skin $2
	varchar(50), --:logo $3
	varchar(50), --:icon $4
	bool, --:allowuserskins $5
	bool, --:allownewregistration $6
	bool, --:usesecureregistration $7
	bool, --:enablemypagefeature $8
	bool, --:usesslonallpages $9
	varchar(255), --:defaultpagekeywords $10
	varchar(255), --:defaultpagedescription $11
	varchar(255), --:defaultpageencoding $12
	varchar(255), --:defaultadditionalmetatags $13
	bool, --:isserveradminsite $14
	bool, --:allowpageskins $15
	bool, --:allowhidemenuonpages $16
	bool, --:useldapauth $17
	bool, --:autocreateldapuseronfirstlogin $18
	varchar(255), --:ldapserver $19
	int4, --:ldapport $20
	varchar(255), --:ldaprootdn $21
	varchar(10), --:ldapuserdnkey $22
	bool, --:allowuserfullnamechange $23
	bool, --:useemailforlogin $24
	bool, --:reallydeleteusers $25
	varchar(50), --:editorskin $26
	varchar(50), --:defaultfriendlyurlpattern $27
	varchar(36), --:siteguid $28
	varchar(255) --:ldapdomain $29
	
) to public;

create or replace function mp_sites_update
(
	int, --:siteid $1
	varchar(128), --:sitename $2
	varchar(100), --:skin $3
	varchar(50), --:logo $4
	varchar(50), --:icon $5
	bool, --:allownewregistration $6
	bool, --:allowuserskins $7
	bool, --:usesecureregistration $8
	bool, --:enablemypagefeature $9
	bool, --:usesslonallpages $10
	varchar(255), --:defaultpagekeywords $11
	varchar(255), --:defaultpagedescription $12
	varchar(255), --:defaultpageencoding $13
	varchar(255), --:defaultadditionalmetatags $14
	bool, --:isserveradminsite $15
	bool, --:allowpageskins $16
	bool, --:allowhidemenuonpages $17
	bool, --:useldapauth $18
	bool, --:autocreateldapuseronfirstlogin $19
	varchar(255), --:ldapserver $20
	int4, --:ldapport $21
	varchar(255), --:ldaprootdn $22
	varchar(10), --:ldapuserdnkey $23
	bool, --:allowuserfullnamechange $24
	bool, --:useemailforlogin $25
	bool, --:reallydeleteusers $26
	varchar(50), --:editorskin $27
	varchar(50), --:defaultfriendlyurlpatternenum $28
	varchar(255) --:ldapdomain $29
	
) returns int4
as '
declare
	_siteid alias for $1;
	_sitename alias for $2;
	_skin alias for $3;
	_logo alias for $4;
	_icon alias for $5;
	_allownewregistration alias for $6;
	_allowuserskins alias for $7;
	_usesecureregistration alias for $8;
	_enablemypagefeature alias for $9;
	_usesslonallpages alias for $10;
	_defaultpagekeywords alias for $11;
	_defaultpagedescription alias for $12;
	_defaultpageencoding alias for $13;
	_defaultadditionalmetatags alias for $14;
	_isserveradminsite alias for $15;
	_allowpageskins alias for $16;
	_allowhidemenuonpages alias for $17;
	_useldapauth alias for $18;
	_autocreateldapuseronfirstlogin alias for $19;
	_ldapserver alias for $20;
	_ldapport alias for $21;
	_ldaprootdn alias for $22;
	_ldapuserdnkey alias for $23;
	_allowuserfullnamechange alias for $24;
	_useemailforlogin alias for $25;
	_reallydeleteusers alias for $26;
	_editorskin alias for $27;
	_defaultfriendlyurlpatternenum alias for $28;
	_ldapdomain alias for $29;
	_rowcount int4;
begin

update	mp_sites
set
    	sitename = _sitename,
	skin = _skin,
	logo = _logo,
	icon = _icon,
	allownewregistration = _allownewregistration,
	allowuserskins = _allowuserskins,
	usesecureregistration = _usesecureregistration,
	enablemypagefeature = _enablemypagefeature,
	usesslonallpages = _usesslonallpages,
	defaultpagekeywords = _defaultpagekeywords,
	defaultpagedescription = _defaultpagedescription,
	defaultpageencoding = _defaultpageencoding,
	defaultadditionalmetatags = _defaultadditionalmetatags,
	isserveradminsite = _isserveradminsite,
	allowpageskins = _allowpageskins,
	allowhidemenuonpages = _allowhidemenuonpages,
	useldapauth = _useldapauth,
	autocreateldapuseronfirstlogin = _autocreateldapuseronfirstlogin,
	ldapserver = _ldapserver,
	ldapport = _ldapport,
	ldapdomain = _ldapdomain,
	ldaprootdn = _ldaprootdn,
	ldapuserdnkey = _ldapuserdnkey,
	allowuserfullnamechange = _allowuserfullnamechange,
	useemailforlogin = _useemailforlogin,
	reallydeleteusers = _reallydeleteusers,
	editorskin = _editorskin,
	defaultfriendlyurlpatternenum = _defaultfriendlyurlpatternenum
where
    	siteid = _siteid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sites_update
(
	int, --:siteid $1
	varchar(128), --:sitename $2
	varchar(100), --:skin $3
	varchar(50), --:logo $4
	varchar(50), --:icon $5
	bool, --:allownewregistration $6
	bool, --:allowuserskins $7
	bool, --:usesecureregistration $8
	bool, --:enablemypagefeature $9
	bool, --:usesslonallpages $10
	varchar(255), --:defaultpagekeywords $11
	varchar(255), --:defaultpagedescription $12
	varchar(255), --:defaultpageencoding $13
	varchar(255), --:defaultadditionalmetatags $14
	bool, --:isserveradminsite $15
	bool, --:allowpageskins $16
	bool, --:allowhidemenuonpages $17
	bool, --:useldapauth $18
	bool, --:autocreateldapuseronfirstlogin $19
	varchar(255), --:ldapserver $20
	int4, --:ldapport $21
	varchar(255), --:ldaprootdn $22
	varchar(10), --:ldapuserdnkey $23
	bool, --:allowuserfullnamechange $24
	bool, --:useemailforlogin $25
	bool, --:reallydeleteusers $26
	varchar(50), --:editorskin $27
	varchar(50), --:defaultfriendlyurlpatternenum $28
	varchar(255) --:ldapdomain $29
	
) to public;








select drop_type('mp_sites_selectall_type');
CREATE TYPE public.mp_sites_selectall_type AS (

		siteid int4 ,
		sitealias varchar(50) ,
		sitename varchar(255) ,
		skin varchar(100) ,
		logo varchar(50) ,
		icon varchar(50) ,
		allowuserskins bool ,
		allowpageskins bool ,
		allownewregistration bool ,
		usesecureregistration bool ,
		enablemypagefeature bool ,
		usesslonallpages bool ,
		defaultpagekeywords varchar(255) ,
		defaultpagedescription varchar(255) ,
		defaultpageencoding varchar(255) ,
		defaultadditionalmetatags varchar(255) ,
		isserveradminsite bool 
);
create or replace function mp_sites_selectall
(
) returns setof mp_sites_selectall_type 
as '
select
		siteid,
		sitealias,
		sitename,
		skin,
		logo,
		icon,
		allowuserskins,
		allowpageskins,
		allownewregistration,
		usesecureregistration,
		enablemypagefeature,
		usesslonallpages,
		defaultpagekeywords,
		defaultpagedescription,
		defaultpageencoding,
		defaultadditionalmetatags,
		isserveradminsite
		
from
		mp_sites; '
security definer language sql;
grant execute on function mp_sites_selectall
(
) to public;

select drop_type('mp_sites_selectone_type');
CREATE TYPE public.mp_sites_selectone_type AS (
		siteid int4 ,
		sitename varchar(255) ,
		skin varchar(100) ,
		logo varchar(50) ,
		icon varchar(50) ,
		allowuserskins bool ,
		allowpageskins bool ,
		allowhidemenuonpages bool ,
		allownewregistration bool ,
		usesecureregistration bool ,
		enablemypagefeature bool ,
		usesslonallpages bool ,
		defaultpagekeywords varchar(255) ,
		defaultpagedescription varchar(255) ,
		defaultpageencoding varchar(255) ,
		defaultadditionalmetatags varchar(255) ,
		isserveradminsite bool ,
		useldapauth bool,
		ldapserver varchar(255),
		autocreateldapuseronfirstlogin bool,
		ldapport int4,
		ldapdomain varchar(255),
		ldaprootdn varchar(255),
		ldapuserdnkey varchar(10),
		allowuserfullnamechange bool ,
		useemailforlogin bool ,
		reallydeleteusers bool,
		editorskin varchar(50),
		defaultfriendlyurlpatternenum varchar(50),
		siteguid varchar(36),
		allowpasswordretrieval boolean,
		allowpasswordreset boolean,
		requiresquestionandanswer boolean,
		requiresuniqueemail boolean,
		maxinvalidpasswordattempts int4,
		passwordattemptwindowminutes int4,
		passwordformat int4,
		minrequiredpasswordlength int4,
		minrequirednonalphanumericcharacters int4,
		passwordstrengthregularexpression text,
		defaultemailfromaddress varchar(100)
		
		
);
create or replace function mp_sites_selectone
(
	int --:siteid $1
) returns setof mp_sites_selectone_type 
as '
select
		siteid,
		sitename,
		skin,
		logo,
		icon,
		allowuserskins,
		allowpageskins,
		allowhidemenuonpages,
		allownewregistration,
		usesecureregistration,
		enablemypagefeature,
		usesslonallpages,
		defaultpagekeywords,
		defaultpagedescription,
		defaultpageencoding,
		defaultadditionalmetatags,
		isserveradminsite,
		useldapauth,
		ldapserver,
		autocreateldapuseronfirstlogin,
		ldapport,
		ldapdomain,
		ldaprootdn,
		ldapuserdnkey,
		allowuserfullnamechange, 
		useemailforlogin,
		reallydeleteusers,
		editorskin,
		defaultfriendlyurlpatternenum,
		siteguid,
		allowpasswordretrieval,
		allowpasswordreset,
		requiresquestionandanswer,
		requiresuniqueemail,
		maxinvalidpasswordattempts,
		passwordattemptwindowminutes,
		passwordformat,
		minrequiredpasswordlength,
		minrequirednonalphanumericcharacters,
		passwordstrengthregularexpression,
		defaultemailfromaddress
from
		mp_sites
		
where
		siteid = $1; '
security definer language sql;
grant execute on function mp_sites_selectone
(
	int --:siteid $1
) to public;


create or replace function mp_sites_selectonebyhost
(
	varchar(255) --:hostname $1
) returns setof mp_sites_selectone_type 
as '
select
		siteid,
		sitename,
		skin,
		logo,
		icon,
		allowuserskins,
		allowpageskins,
		allowhidemenuonpages,
		allownewregistration,
		usesecureregistration,
		enablemypagefeature,
		usesslonallpages,
		defaultpagekeywords,
		defaultpagedescription,
		defaultpageencoding,
		defaultadditionalmetatags,
		isserveradminsite,
		useldapauth,
		ldapserver,
		autocreateldapuseronfirstlogin,
		ldapport,
		ldapdomain,
		ldaprootdn,
		ldapuserdnkey,
		allowuserfullnamechange, 
		useemailforlogin,
		reallydeleteusers,
		editorskin,
		defaultfriendlyurlpatternenum,
		siteguid,
		allowpasswordretrieval,
		allowpasswordreset,
		requiresquestionandanswer,
		requiresuniqueemail,
		maxinvalidpasswordattempts,
		passwordattemptwindowminutes,
		passwordformat,
		minrequiredpasswordlength,
		minrequirednonalphanumericcharacters,
		passwordstrengthregularexpression,
		defaultemailfromaddress
from
		mp_sites
		
where
		siteid = coalesce(
				(select siteid from mp_sitehosts where hostname = $1 limit 1),
				 (select siteid from mp_sites order by siteid limit 1)
				)
				; '
security definer language sql;
grant execute on function mp_sites_selectonebyhost
(
	varchar(255) --:hostname $1
) to public;











create or replace function mp_userroles_delete
(
   
	int, --:roleid $1
	int --:userid $2
) returns int4
as '
declare
	_roleid alias for $1;
	_userid alias for $2;
	_rowcount int4;
begin

	delete from 
    mp_userroles
where
    userid = _userid
    and
    roleid = _roleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userroles_delete
(
   
	int, --:roleid $1
	int --:userid $2
) to public;

create or replace function mp_userroles_insert
(
	int, --:roleid $1
	int --:userid $2
    
) returns int4 
as '
declare
	_roleid alias for $1;
	_userid alias for $2;
	t_found int4;
	_rowcount int4;

begin

_rowcount := 0;
select into t_found 1 from
    mp_userroles
	where
	    userid=_userid
	    and
	    roleid=_roleid limit 1;

if not found then

    insert into mp_userroles
    (
        userid,
        roleid
    )
    values
    (
        _userid,
        _roleid
    );   
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
end if;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userroles_insert
(
	int, --:roleid $1
	int --:userid $2
    
) to public;

select drop_type('mp_userroles_selectbyroleid_type');
CREATE TYPE public.mp_userroles_selectbyroleid_type AS (
  
    userid int4 ,
    name varchar(50) ,
    email varchar(100) 
);
create or replace function mp_userroles_selectbyroleid
(
	int --:roleid $1
) returns setof mp_userroles_selectbyroleid_type 
as '
select  
    mp_userroles.userid,
    name,
    email
from
    mp_userroles
    
inner join 
    mp_users on mp_users.userid = mp_userroles.userid
where   
    mp_userroles.roleid = $1; '
security definer language sql;
grant execute on function mp_userroles_selectbyroleid
(
	int --:roleid $1
) to public;


create or replace function mp_userroles_selectnotinrole
(
	int, --:siteid $1
	int --:rolid $2
) returns setof mp_userroles_selectbyroleid_type 
as '
select  
    u.userid,
    u.name,
    u.email
from
    mp_users u 
    
left outer join 
    mp_userroles  ur
    
on ur.userid = u.userid
and ur.roleid = $2

where   
    u.siteid = $1
    and ur.roleid is null
order by u.name
    ; '
security definer language sql;
grant execute on function mp_userroles_selectnotinrole
(
	int, --:siteid $1
	int --:rolid $2
) to public;



-- added siteid param 5/12/2005
create or replace function mp_users_count
(
	int --:siteid $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_users
where siteid = $1; '
security definer language sql;


grant execute on function mp_users_count
(
	int --:siteid $1
) to public;

create or replace function mp_users_decrementtotalposts
(
	int --:userid $1
) returns int4
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

update		mp_users
set			totalposts = totalposts - 1
where		userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_decrementtotalposts
(
	int --:userid $1
) to public;

create or replace function mp_users_delete
(
	int --:userid $1
) returns int4
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

	delete from 
    mp_users
where
    userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_delete
(
	int --:userid $1
) to public;


-- added 5/6/2006

create or replace function mp_users_updatelastactivitytime
(
	varchar(36), --:userguid $1
	timestamp --:lastactivitydate $2
) returns int4
as '
declare
	_userguid alias for $1;
	_lastactivitydate alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set lastactivitydate = _lastactivitydate
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_updatelastactivitytime
(
	varchar(36), --:userguid $1
	timestamp --:lastactivitydate $2
) to public;


-- 

create or replace function mp_users_updatelastlogintime
(
	varchar(36), --:userguid $1
	timestamp --:lastlogindate $2
) returns int4
as '
declare
	_userguid alias for $1;
	_lastlogindate alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set lastlogindate = _lastlogindate
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_updatelastlogintime
(
	varchar(36), --:userguid $1
	timestamp --:lastlogindate $2
) to public;

--

create or replace function mp_users_accountlockout
(
	varchar(36), --:userguid $1
	timestamp --:lastlockoutdate $2
) returns int4
as '
declare
	_userguid alias for $1;
	_lastlockoutdate alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set islockedout = true,
    	lastlockoutdate = _lastlockoutdate
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_accountlockout
(
	varchar(36), --:userguid $1
	timestamp --:lastlockoutdate $2
) to public;

--

create or replace function mp_users_updatelastpasswordchangedate
(
	varchar(36), --:userguid $1
	timestamp --:lastpasswordchangeddate $2
) returns int4
as '
declare
	_userguid alias for $1;
	_lastpasswordchangeddate alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set 
    	lastpasswordchangeddate = _lastpasswordchangeddate
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_updatelastpasswordchangedate
(
	varchar(36), --:userguid $1
	timestamp --:lastpasswordchangeddate $2
) to public;



-- added 2007-01-18

create or replace function mp_users_setfailedpasswordattemptstartwindow
(
	varchar(36), --:userguid $1
	timestamp --:windowstarttime $2
) returns int4
as '
declare
	_userguid alias for $1;
	_windowstarttime alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set 
    	failedpasswordattemptwindowstart = _windowstarttime
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_setfailedpasswordattemptstartwindow
(
	varchar(36), --:userguid $1
	timestamp --:windowstarttime $2
) to public;

create or replace function mp_users_setfailedpasswordattemptcount
(
	varchar(36), --:userguid $1
	int --:attemptcount $2
) returns int4
as '
declare
	_userguid alias for $1;
	_attemptcount alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set 
    	failedpasswordattemptcount = _attemptcount
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_setfailedpasswordattemptcount
(
	varchar(36), --:userguid $1
	int --:attemptcount $2
) to public;



create or replace function mp_users_setfailedpasswordanswerattemptstartwindow
(
	varchar(36), --:userguid $1
	timestamp --:windowstarttime $2
) returns int4
as '
declare
	_userguid alias for $1;
	_windowstarttime alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set 
    	failedpasswordanswerattemptwindowstart = _windowstarttime
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_setfailedpasswordanswerattemptstartwindow
(
	varchar(36), --:userguid $1
	timestamp --:windowstarttime $2
) to public;


create or replace function mp_users_setfailedpasswordanswerattemptcount
(
	varchar(36), --:userguid $1
	int --:attemptcount $2
) returns int4
as '
declare
	_userguid alias for $1;
	_attemptcount alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set 
    	failedpasswordanswerattemptcount = _attemptcount
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_setfailedpasswordanswerattemptcount
(
	varchar(36), --:userguid $1
	int --:attemptcount $2
) to public;

-- end added 2007-01-18

--

create or replace function mp_users_setregistrationguid
(
	varchar(36), --:userguid $1
	varchar(36) --:registerconfirmguid $2
) returns int4
as '
declare
	_userguid alias for $1;
	_registerconfirmguid alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set islockedout = true,
    	registerconfirmguid = _registerconfirmguid
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_setregistrationguid
(
	varchar(36), --:userguid $1
	varchar(36) --:registerconfirmguid $2
) to public;

--

create or replace function mp_users_confirmregistration
(
	varchar(36), --:emptyguid $1
	varchar(36) --:registerconfirmguid $2
) returns int4
as '
declare
	_emptyguid alias for $1;
	_registerconfirmguid alias for $2;
	_rowcount int4;
begin

    update 
    mp_users
    set islockedout = false,
    	registerconfirmguid = _emptyguid
where
    registerconfirmguid = _registerconfirmguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_confirmregistration
(
	varchar(36), --:emptyguid $1
	varchar(36) --:registerconfirmguid $2
) to public;

--

create or replace function mp_users_clearlockout
(
	varchar(36) --:userguid $1
	
) returns int4
as '
declare
	_userguid alias for $1;
	_rowcount int4;
begin

    update 
    mp_users
    set islockedout = false
    
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_clearlockout
(
	varchar(36) --:userguid $1
	
) to public;

--

create or replace function mp_users_updatepasswordquestionandanswer
(
	varchar(36), --:userguid $1
	varchar(255), --:passwordquestion $2
	varchar(255) --:passwordanswer $3
) returns int4
as '
declare
	_userguid alias for $1;
	_passwordquestion alias for $2;
	_passwordanswer alias for $3;
	_rowcount int4;
begin

    update 
    mp_users
    set passwordquestion = _passwordquestion,
    	passwordanswer = _passwordanswer
where
    userguid = _userguid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_updatepasswordquestionandanswer
(
	varchar(36), --:emptyguid $1
	varchar(255), --:passwordquestion $2
	varchar(255) --:passwordanswer $3
) to public;

--

create or replace function mp_users_countonlinesince
(
	int, --:siteid $1
	timestamp --:sincetime $2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_users
where siteid = $1 and lastactivitydate > $2; '
security definer language sql;


grant execute on function mp_users_countonlinesince
(
	int, --:siteid $1
	timestamp --:sincetime $2
) to public;


create or replace function mp_sites_updateextendedproperties
(
	int, --:siteid $1
boolean, --:allowpasswordretrieval $2
boolean, --:allowpasswordreset $3
boolean, --:requiresquestionandanswer $4
int, --:maxinvalidpasswordattempts $5
int, --:passwordattemptwindowminutes $6
boolean, --:requiresuniqueemail $7
int, --:passwordformat $8
int, --:minrequiredpasswordlength $9
int, --:minrequirednonalphanumericcharacters $10
text, --:passwordstrengthregularexpression $11
varchar(100) --:defaultemailfromaddress $12
) returns int4
as '
declare
	_siteid alias for $1;
_allowpasswordretrieval alias for $2;
_allowpasswordreset alias for $3;
_requiresquestionandanswer alias for $4;
_maxinvalidpasswordattempts alias for $5;
_passwordattemptwindowminutes alias for $6;
_requiresuniqueemail alias for $7;
_passwordformat alias for $8;
_minrequiredpasswordlength alias for $9;
_minrequirednonalphanumericcharacters alias for $10;
_passwordstrengthregularexpression alias for $11;
_defaultemailfromaddress alias for $12;
_rowcount int4;
begin

update mp_sites
set
allowpasswordretrieval = _allowpasswordretrieval,
allowpasswordreset = _allowpasswordreset,
requiresquestionandanswer = _requiresquestionandanswer,
maxinvalidpasswordattempts = _maxinvalidpasswordattempts,
passwordattemptwindowminutes = _passwordattemptwindowminutes,
requiresuniqueemail = _requiresuniqueemail,
passwordformat = _passwordformat,
minrequiredpasswordlength = _minrequiredpasswordlength,
minrequirednonalphanumericcharacters = _minrequirednonalphanumericcharacters,
passwordstrengthregularexpression = _passwordstrengthregularexpression,
defaultemailfromaddress = _defaultemailfromaddress
where siteid = _siteid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sites_updateextendedproperties
(
	int, --:siteid $1
boolean, --:allowpasswordretrieval $2
boolean, --:allowpasswordreset $3
boolean, --:requiresquestionandanswer $4
int, --:maxinvalidpasswordattempts $5
int, --:passwordattemptwindowminutes $6
boolean, --:requiresuniqueemail $7
int, --:passwordformat $8
int, --:minrequiredpasswordlength $9
int, --:minrequirednonalphanumericcharacters $10
text, --:passwordstrengthregularexpression $11
varchar(100) --:defaultemailfromaddress $12
) to public;







create or replace function mp_users_flagasdeleted
(
	int --:userid $1
) returns int4
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

 update mp_users
 set isdeleted = true
where
    userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_flagasdeleted
(
	int --:userid $1
) to public;






select drop_type('mp_users_getuserroles_type');
CREATE TYPE public.mp_users_getuserroles_type AS (
  
    		rolename varchar(50) ,
    		roleid int4 
);
create or replace function mp_users_getuserroles
(
	int, --:siteid $1
	int --:userid $2
) returns setof mp_users_getuserroles_type 
as '
select  
    		mp_roles.rolename,
    		mp_roles.roleid
from		 mp_userroles
  
inner join 	mp_users 
on 		mp_userroles.userid = mp_users.userid
inner join 	mp_roles 
on 		mp_userroles.roleid = mp_roles.roleid
where   	mp_users.siteid = $1
		and mp_users.userid = $2; '
security definer language sql;
grant execute on function mp_users_getuserroles
(
	int, --:siteid $1
	int --:userid $2
) to public;

create or replace function mp_users_incrementtotalposts
(
	int --:userid $1
) returns int4
as '
declare
	_userid alias for $1;
	_rowcount int4;
begin

update		mp_users
set			totalposts = totalposts + 1
where		userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_incrementtotalposts
(
	int --:userid $1
) to public;

create or replace function mp_users_insert
(
	int, --:siteid $1
	varchar(50), --:name $2
	varchar(50), --:loginname $3
	varchar(100), --:email $4
	varchar(128), --:password $5
	char(36), --:userguid $6
	timestamp --datecreated $7
) returns int4 
as '
insert into 		mp_users
(
			siteid,
    			name,
    			loginname,
    			email,
    			password,
			userguid,
			datecreated
	
)
values
(
			$1,
    			$2,
    			$3,
    			$4,
			$5,
			$6,
			$7
);
select		cast(currval(''mp_users_userid_seq'') as int4); '
security definer language sql;
grant execute on function mp_users_insert
(
	int, --:siteid $1
	varchar(50), --:name $2
	varchar(50), --:loginname $3
	varchar(100), --:email $4
	varchar(128), --:password $5
	char(36), --:userguid $6
	timestamp --datecreated $7
) to public;







select drop_type('mp_users_loginbyemail_type');
CREATE TYPE public.mp_users_loginbyemail_type AS (

	username varchar(50) 
);
create or replace function mp_users_loginbyemail
(
   
	int,  --:siteid $1
	varchar(100),  --:email $2
	varchar(128)  --:password $3

) returns setof mp_users_loginbyemail_type 
as '
select
	name as username
from
    mp_users
where
		siteid = $1
    		and email = $2
  		and password = $3; '
security definer language sql;
grant execute on function mp_users_loginbyemail
(
   
	int,  --:siteid $1
	varchar(100),  --:email $2
	varchar(128)  --:password $3

) to public;




select drop_type('mp_users_login_type');
CREATE TYPE public.mp_users_login_type AS (

	username varchar(50) 
);
create or replace function mp_users_login
(
   
	int,  --:siteid $1
	varchar(50),  --:loginname $2
	varchar(128)  --:password $3

) returns setof mp_users_login_type 
as '
select
	name as username
from
    mp_users
where
		siteid = $1
    		and loginname = $2
  		and password = $3; '
security definer language sql;
grant execute on function mp_users_login
(
   
	int,  --:siteid $1
	varchar(50),  --:loginname $2
	varchar(128)  --:password $3

) to public;











select drop_type('mp_users_select_type');
CREATE TYPE public.mp_users_select_type AS (
  
    userid int4 ,
    email varchar(100),
    name varchar(50),
    password varchar(128)
);

create or replace function mp_users_select
(
	int --:siteid $1
) returns setof mp_users_select_type 
as '
select  
    userid,
    email,
    name,
    password
from
    mp_users
where siteid = $1
    
order by email; '
security definer language sql;


grant execute on function mp_users_select
(
	int --:siteid $1
) to public;







select drop_type('mp_users_smartdropdown_type');
CREATE TYPE public.mp_users_smartdropdown_type AS (
  
    userid int4 ,
    siteuser varchar(100)  
);

create or replace function mp_users_smartdropdown
(
    
	int, --:siteid $1
	varchar(50), --:query $2
	int --:rowstoget $3
) returns setof mp_users_smartdropdown_type 
as '


SELECT 		u1.userid,
		u1.name AS siteuser

FROM		mp_users u1

WHERE		u1.siteid = $1
		AND u1.name LIKE $2 

UNION

SELECT 		u2.userid,
		u2.email As siteuser

FROM		mp_users u2

WHERE		u2.siteid = $1
		AND u2.email LIKE $2 

ORDER BY	siteuser

LIMIT $3   ;  '
security definer language sql;
grant execute on function mp_users_smartdropdown
(
	int, --:siteid $1
	varchar(50), --:query $2
	int --:rowstoget $3
) to public;







create or replace function mp_users_selectbyemail
(
    
	int, --:siteid $1
	varchar(100) --:email $2
) returns setof mp_users 
as '
select	*
from
    mp_users
where
	siteid = $1
   	and email = $2; '
security definer language sql;
grant execute on function mp_users_selectbyemail
(
    
	int, --:siteid $1
	varchar(100) --:email $2
) to public;


create or replace function mp_users_selectbyloginname
(
    
	int, --:siteid $1
	varchar(50) --:loginname $2
) returns setof mp_users 
as '
select	*
from
    mp_users
where
	siteid = $1
   	and loginname = $2; '
security definer language sql;
grant execute on function mp_users_selectbyloginname
(
    
	int, --:siteid $1
	varchar(50) --:loginname $2
) to public;


create or replace function mp_users_selectone
(
	int --:userid $1
) returns setof mp_users 
as '
select	*
from		mp_users
where	userid = $1; '
security definer language sql;
grant execute on function mp_users_selectone
(
	int --:userid $1
) to public;


-- added 5/4/2006
create or replace function mp_users_selectonebyguid
(
	varchar(36) --:userguid $1
) returns setof mp_users 
as '
select	*
from		mp_users
where	userguid = $1; '
security definer language sql;
grant execute on function mp_users_selectonebyguid
(
	varchar(36) --:userguid $1
) to public;

-- added 11/7/2006

create or replace function mp_users_getusersonlinesince
(
    
	int, --:siteid $1
	timestamp --:sincetime $2
) returns setof mp_users 
as '
select	*
from
    mp_users
where
	siteid = $1
   	and lastactivitydate > $2; '
security definer language sql;
grant execute on function mp_users_getusersonlinesince
(
    
	int, --:siteid $1
	timestamp --:sincetime $2
) to public;

-- 



select drop_type('mp_users_selectpage_type');
CREATE TYPE public.mp_users_selectpage_type AS (
	userid int4 ,
	siteid int4 ,
	name varchar(50) ,
	email varchar(100) ,
	password varchar(128) ,
	gender char(1),
	profileapproved bool ,
	approvedforforums bool ,
	trusted bool ,
	displayinmemberlist bool ,
	websiteurl varchar(100),
	country varchar(100),
	state varchar(100),
	occupation varchar(100),
	interests varchar(100),
	msn varchar(50),
	yahoo varchar(50),
	aim varchar(50),
	icq varchar(50),
	totalposts int4 ,
	avatarurl varchar(255) ,
	timeoffsethours int4 ,
	signature varchar(255),
	datecreated timestamp ,
	userguid varchar(36) ,
	totalpages int4
);
create or replace function mp_users_selectpage
(
	int, --:pagenumber $1
	int, --:pagesize $2
	varchar(1), --:usernamebeginswith $3
	int --:siteid $4
) returns setof mp_users_selectpage_type 
as '
declare
	_pagenumber alias for $1;
	_pagesize alias for $2;
	_usernamebeginswith alias for $3;
	_siteid alias for $4;
	 _pagelowerbound int;
	 _pageupperbound int;
	 _totalrows int;
	 _totalpages int;
	 _remainder int;
	_rec mp_users_selectpage_type%ROWTYPE;

begin

_pagelowerbound := (_pagesize * _pagenumber) - _pagesize;
_pageupperbound := _pagelowerbound + _pagesize + 1;

for _rec in
	select 
		userid ,
		siteid ,
		name ,
		email ,
		password ,
		gender ,
		profileapproved ,
		approvedforforums ,
		trusted ,
		displayinmemberlist ,
		websiteurl ,
		country ,
		state ,
		occupation ,
		interests ,
		msn ,
		yahoo ,
		aim ,
		icq ,
		totalposts  ,
		avatarurl ,
		timeoffsethours  ,
		signature ,
		datecreated ,
		userguid,
		_totalpages as totalpages

	from 		mp_users 
	where 	profileapproved = true
	 and 	displayinmemberlist = true  
	 and 	siteid = _siteid
	 and 	isdeleted = false
	 and	(_usernamebeginswith is null 
		or _usernamebeginswith = ''''
		or substring(name from 1 for 1) = _usernamebeginswith)
	order by 	name
	limit 	_pagesize
	offset 	_pagelowerbound
loop
	return next _rec;
end loop;
return;
end'
security definer language plpgsql;
grant execute on function mp_users_selectpage
(
	int, --:pagenumber $1
	int, --:pagesize $2
	varchar(1), --:usernamebeginswith $3
	int --:siteid $4
) to public;

create or replace function mp_users_update
(
    
	int,    --:userid $1
	varchar(100),    --:name $2
	varchar(50),    --:loginname $3
	varchar(100),    --:email $4
	varchar(128), --:password $5
	char(1), --:gender $6
	bool, --:profileapproved $7
	bool, --:approvedforforums $8
	bool, --:trusted $9
	bool, --:displayinmemberlist $10
	varchar(100), --:websiteurl $11
	varchar(100), --:country $12
	varchar(100), --:state $13
	varchar(100), --:occupation $14
	varchar(100), --:interests $15
	varchar(50), --:msn $16
	varchar(50), --:yahoo $17
	varchar(50), --:aim $18
	varchar(50), --:icq $19
	varchar(255), --:avatarurl $20
	varchar(255), --:signature $21
	varchar(100), --:skin $22,
	varchar(100), --:loweredemail $23,
	varchar(255), --:passwordquestion $24,
	varchar(255), --:passwordanswer $25,
	text, --:comment $26,
	int	--:timeoffsethours $27
) returns int4
as '
declare
	_userid alias for $1;
	_name alias for $2;
	_loginname alias for $3;
	_email alias for $4;
	_password alias for $5;
	_gender alias for $6;
	_profileapproved alias for $7;
	_approvedforforums alias for $8;
	_trusted alias for $9;
	_displayinmemberlist alias for $10;
	_websiteurl alias for $11;
	_country alias for $12;
	_state alias for $13;
	_occupation alias for $14;
	_interests alias for $15;
	_msn alias for $16;
	_yahoo alias for $17;
	_aim alias for $18;
	_icq alias for $19;
	_avatarurl alias for $20;
	_signature alias for $21;
	_skin alias for $22;
	_loweredemail alias for $23;
	_passwordquestion alias for $24;
	_passwordanswer alias for $25;
	_comment alias for $26;
	_timeoffsethours alias for $27;
	_rowcount int4;
begin

update		mp_users
set			name = _name,
			loginname = _loginname,
			email = _email,
    			password = _password,
			gender = _gender,
			profileapproved = _profileapproved,
			approvedforforums = _approvedforforums,
			trusted = _trusted,
			displayinmemberlist = _displayinmemberlist,
			websiteurl = _websiteurl,
			country = _country,
			state = _state,
			occupation = _occupation,
			interests = _interests,
			msn = _msn,
			yahoo = _yahoo,
			aim = _aim,
			icq = _icq,
			avatarurl = _avatarurl,
			signature = _signature,
			skin = _skin,
			loweredemail = _loweredemail,
			passwordquestion = _passwordquestion,
			passwordanswer = _passwordanswer,
			comment = _comment,
			timeoffsethours = _timeoffsethours
			
where		userid = _userid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_users_update
(
    
	int,    --:userid $1
	varchar(100),    --:name $2
	varchar(50),    --:loginname $3
	varchar(100),    --:email $4
	varchar(128), --:password $5
	char(1), --:gender $6
	bool, --:profileapproved $7
	bool, --:approvedforforums $8
	bool, --:trusted $9
	bool, --:displayinmemberlist $10
	varchar(100), --:websiteurl $11
	varchar(100), --:country $12
	varchar(100), --:state $13
	varchar(100), --:occupation $14
	varchar(100), --:interests $15
	varchar(50), --:msn $16
	varchar(50), --:yahoo $17
	varchar(50), --:aim $18
	varchar(50), --:icq $19
	varchar(255), --:avatarurl $20
	varchar(255), --:signature $21
	varchar(100), --:skin $22,
	varchar(100), --:loweredemail $23,
	varchar(255), --:passwordquestion $24,
	varchar(255), --:passwordanswer $25,
	text, --:comment $26,
	int	--:timeoffsethours $27
) to public;

create or replace function mp_mp_galleryimages_delete
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from  mp_galleryimages
where	itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_mp_galleryimages_delete
(
	int --:itemid $1
) to public;

create or replace function mp_mp_galleryimages_insert
(
	int, --:moduleid $1
	int, --:displayorder $2
	varchar(255), --:caption $3
	text, --:description $4
	text, --:metadataxml $5
	varchar(100), --:imagefile $6
	varchar(100), --:webimagefile $7
	varchar(100), --:thumbnailfile $8
	timestamp, --:uploaddate $9
	varchar(100) --:uploaduser $10
	
) returns int4 
as '
insert into 			mp_galleryimages 
(
				moduleid,
				displayorder,
				caption,
				description,
				metadataxml,
				imagefile,
				webimagefile,
				thumbnailfile,
				uploaddate,
				uploaduser
) 
values 
(
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10
				
);
select cast(currval(''mp_galleryimages_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_mp_galleryimages_insert
(
	int, --:moduleid $1
	int, --:displayorder $2
	varchar(255), --:caption $3
	text, --:description $4
	text, --:metadataxml $5
	varchar(100), --:imagefile $6
	varchar(100), --:webimagefile $7
	varchar(100), --:thumbnailfile $8
	timestamp, --:uploaddate $9
	varchar(100) --:uploaduser $10
	
) to public;

select drop_type('mp_mp_galleryimages_selectall_type');
CREATE TYPE public.mp_mp_galleryimages_selectall_type AS (

		itemid int4 ,
		moduleid int4 ,
		displayorder int4 ,
		caption varchar(255) ,
		description text ,
		imagefile varchar(100) ,
		webimagefile varchar(100) ,
		thumbnailfile varchar(100) ,
		uploaddate timestamp ,
		uploaduser varchar(100)
);
create or replace function mp_mp_galleryimages_selectall
(
) returns setof mp_mp_galleryimages_selectall_type 
as '
select
		itemid,
		moduleid,
		displayorder,
		caption,
		description,
		imagefile,
		webimagefile,
		thumbnailfile,
		uploaddate,
		uploaduser
		
from
		mp_galleryimages; '
security definer language sql;
grant execute on function mp_mp_galleryimages_selectall
(
) to public;

select drop_type('mp_mp_galleryimages_selectone_type');
CREATE TYPE public.mp_mp_galleryimages_selectone_type AS (
		itemid int4 ,
		moduleid int4 ,
		displayorder int4 ,
		caption varchar(255) ,
		description text ,
		metadataxml text ,
		imagefile varchar(100) ,
		webimagefile varchar(100) ,
		thumbnailfile varchar(100) ,
		uploaddate timestamp ,
		uploaduser varchar(100)

);
create or replace function mp_mp_galleryimages_selectone
(
	int --:itemid $1
) returns setof mp_mp_galleryimages_selectone_type 
as '
select
		itemid,
		moduleid,
		displayorder,
		caption,
		description,
		metadataxml,
		imagefile,
		webimagefile,
		thumbnailfile,
		uploaddate,
		uploaduser
		
from
		mp_galleryimages
		
where
		itemid = $1; '
security definer language sql;
grant execute on function mp_mp_galleryimages_selectone
(
	int --:itemid $1
) to public;

create or replace function mp_mp_galleryimages_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:displayorder $3
	varchar(255),  --:caption $4
	text,  --:description $5
	text,  --:metadataxml $6
	varchar(100),  --:imagefile $7
	varchar(100), --:webimagefile $8
	varchar(100),  --:thumbnailfile $9
	timestamp,  --:uploaddate $10
	varchar(100)  --:uploaduser $11
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_displayorder alias for $3;
	_caption alias for $4;
	_description alias for $5;
	_metadataxml alias for $6;
	_imagefile alias for $7;
	_webimagefile alias for $8;
	_thumbnailfile alias for $9;
	_uploaddate alias for $10;
	_uploaduser alias for $11;
	_rowcount int4;
begin

update 		mp_galleryimages 
set
			moduleid = _moduleid,
			displayorder = _displayorder,
			caption = _caption,
			description = _description,
			metadataxml = _metadataxml,
			imagefile = _imagefile,
			webimagefile = _webimagefile,
			thumbnailfile = _thumbnailfile,
			uploaddate = _uploaddate,
			uploaduser = _uploaduser
			
where
			itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_mp_galleryimages_update
(
	
	int,  --:itemid $1
	int,  --:moduleid $2
	int,  --:displayorder $3
	varchar(255),  --:caption $4
	text,  --:description $5
	text,  --:metadataxml $6
	varchar(100),  --:imagefile $7
	varchar(100), --:webimagefile $8
	varchar(100),  --:thumbnailfile $9
	timestamp,  --:uploaddate $10
	varchar(100)  --:uploaduser $11
) to public;



-- begin rss feed

create or replace function mp_rssfeeds_delete
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

	delete from  mp_rssfeeds
where	itemid = _itemid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_rssfeeds_delete
(
	int --:itemid $1
) to public;




create or replace function mp_rssfeeds_insert
(
	int, --:moduleid $1
	int, --:userid $2
	varchar(100), --:author $3
	varchar(255), --:url $4
	varchar(255) --:rssurl $5
	
) returns int4 
as '
insert into 	mp_rssfeeds
(				
                moduleid,
                createddate,
                userid,
                author,
                url,
                rssurl
) 
values 
(				
                $1, --:moduleid
                current_timestamp(3), --:createddate
                $2, --:userid
                $3, --:author
                $4, --:url
                $5 --:rssurl
);
select cast(currval(''mp_rssfeeds_itemid_seq'') as int4); '
security definer language sql;
grant execute on function mp_rssfeeds_insert
(
	int, --:moduleid $1
	int, --:userid $2
	varchar(100), --:author $3
	varchar(255), --:url $4
	varchar(255) --:rssurl $5
	
) to public;



select drop_type('mp_rssfeeds_select_one_type');
CREATE TYPE public.mp_rssfeeds_select_one_type AS (
	itemid int4,
	moduleid int4,
	createddate timestamp,
	userid int4,
	author varchar(100),
	url varchar(255),
	rssurl varchar(255)
);


create or replace function mp_rssfeeds_select_one 
(
	int --:itemid $1
) returns setof mp_rssfeeds_select_one_type
as '

select
        itemid,
        moduleid,
        createddate,
        userid,
        author,
        url,
        rssurl
from
        mp_rssfeeds
        
where
        itemid = $1 ; '
security definer language sql;
grant execute on function mp_rssfeeds_select_one (
	int --:itemid $1
) to public;



select drop_type('mp_rssfeeds_select_type');
CREATE TYPE public.mp_rssfeeds_select_type AS (
	itemid int4,
	moduleid int4,
	createddate timestamp,
	userid int4,
	author varchar(100),
	url varchar(255),
	rssurl varchar(255)
);
create or replace function mp_rssfeeds_select
(
	int --:moduleid $1
) returns setof mp_rssfeeds_select_type
as '

select
        itemid,
        moduleid,
        createddate,
        userid,
        author,
        url,
        rssurl
from
        mp_rssfeeds
        
where
        moduleid = $1 ; '
security definer language sql;
grant execute on function mp_rssfeeds_select(
	int --:moduleid $1
	
) to public;




create or replace function mp_rssfeeds_update
(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(100), --:author $3
	varchar(255), --:url $4
	varchar(255) --:rssurl $5
	
) returns int4
as '
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_author alias for $3;
	_url alias for $4;
	_rssurl alias for $5;
	_rowcount int4;
begin
update 		mp_rssfeeds

set
            moduleid = _moduleid, --:moduleid
            author = _author, --:author
            url = _url, --:url
            rssurl = _rssurl --:rssurl
            
where
            itemid = _itemid ; --:itemid
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_rssfeeds_update (
	int, --:itemid $1
	int, --:moduleid $2
	varchar(100), --:author $3
	varchar(255), --:url $4
	varchar(255) --:rssurl $5
	
) to public;


-- end rss feed

-- Event Calendar

create or replace function mp_calendarevents_delete 
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin

/*
Author:   			
Created: 			4/17/2005
Last Modified: 			4/17/2005
*/	
	
	delete from mp_calendarevents
	where itemid = _itemid;
	
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_calendarevents_delete (
	int --:itemid $1
) to public;


select drop_type('mp_calendarevents_select_one_type');
CREATE TYPE public.mp_calendarevents_select_one_type as (
	itemid int4,
	moduleid int4,
	title varchar(255),
	description text,
	imagename varchar(100),
	eventdate timestamp,
	starttime timestamp,
	endtime timestamp,
	createddate timestamp,
	userid int4
);


select drop_type('mp_calendarevents_select_bydate_type');
CREATE TYPE public.mp_calendarevents_select_bydate_type as (
	itemid int4,
	moduleid int4,
	title varchar(255),
	description text,
	imagename varchar(100),
	eventdate timestamp,
	starttime timestamp,
	endtime timestamp,
	createddate timestamp,
	userid int4
);


create or replace function mp_calendarevents_select_one (
	int --:itemid $1
	
) returns setof mp_calendarevents_select_one_type
as '
/*
Author:   			
Created: 			4/17/2005
Last Modified: 			4/17/2005
*/

select
        itemid,
        moduleid,
        title,
        description,
        imagename,
        eventdate,
        starttime,
        endtime,
        createddate,
        userid
from
        mp_calendarevents
        
where
        itemid = $1;'
security definer language sql;
grant execute on function mp_calendarevents_select_one (
	int --:itemid $1
	
) to public;


create or replace function mp_calendarevents_select_bydate(
	int, --:moduleid $1
	date, --:begindate $2
	date  --:enddate $3
) returns setof mp_calendarevents_select_bydate_type
as '
/*
Author:   			
Created: 			4/17/2005
Last Modified: 			4/17/2005
*/

select
        itemid,
        moduleid,
        title,
        description,
        imagename,
        eventdate,
        starttime,
        endtime,
        createddate,
        userid
from
        mp_calendarevents
        
where   moduleid = $1
	AND  eventdate >= $2
        AND eventdate <= $3

order by eventdate, starttime;'
		
		
security definer language sql;
grant execute on function mp_calendarevents_select_bydate(
	int, --:moduleid $1
	date, --:begindate $2
	date  --:enddate $3
) to public;


create or replace function mp_calendarevents_insert(
	int, --:moduleid $1
	varchar(255), --:title $2
	text, --:description $3
	varchar(100), --:imagename $4
	timestamp, --:eventdate $5
	timestamp, --:starttime $6
	timestamp, --:endtime $7
	int --:userid $8
) returns int4
as '
/*
Author:   			
Created: 			4/17/2005
Last Modified: 			4/17/2005

*/

insert into 	mp_calendarevents
(				
                moduleid,
                title,
                description,
                imagename,
                eventdate,
                starttime,
                endtime,
                createddate,
                userid
) 
values 
(				
                $1, --:moduleid
                $2, --:title
                $3, --:description
                $4, --:imagename
                $5, --:eventdate
                $6, --:starttime
                $7, --:endtime
                current_timestamp(3), --:createddate
                $8 --:userid
);

select cast(currval(''mp_calendarevents_itemid_seq'') as int4);'
security definer language sql;
grant execute on function mp_calendarevents_insert(
	int, --:moduleid $1
	varchar(255), --:title $2
	text, --:description $3
	varchar(100), --:imagename $4
	timestamp, --:eventdate $5
	timestamp, --:starttime $6
	timestamp, --:endtime $7
	int --:userid $8
) to public;

create or replace function mp_calendarevents_update(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(255), --:title $3
	text, --:description $4
	varchar(100), --:imagename $5
	timestamp, --:eventdate $6
	timestamp, --:starttime $7
	timestamp, --:endtime $8
	int --:userid $9
) returns int
as '
/*
Author:   			
Updated By:			Joseph Hill
Created: 			4/17/2005
Last Modified: 			8/27/2005
*/
declare
	_itemid alias for $1;
	_moduleid alias for $2;
	_title alias for $3;
	_description alias for $4;
	_imagename alias for $5;
	_eventdate alias for $6;
	_starttime alias for $7;
	_endtime alias for $8;
	_userid alias for $9;
	_rowcount int4;
begin

update 		mp_calendarevents

set
            moduleid = _moduleid, --:moduleid
            title = _title, --:title
            description = _description, --:description
            imagename = _imagename, --:imagename
            eventdate = _eventdate, --:eventdate
            starttime = _starttime, --:starttime
            endtime = _endtime, --:endtime
            userid = _userid --:userid
            
where
            itemid = _itemid; --:itemid

GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_calendarevents_update(
	int, --:itemid $1
	int, --:moduleid $2
	varchar(255), --:title $3
	text, --:description $4
	varchar(100), --:imagename $5
	timestamp, --:eventdate $6
	timestamp, --:starttime $7
	timestamp, --:endtime $8
	int --:userid $9
) to public;






-- end event calendar










-- Begin Friendly Urls

create or replace function mp_friendlyurls_delete 
(
	int --:urlid $1
) returns int4
as '
declare
	_urlid alias for $1;
	_rowcount int4;
begin

	
	delete from mp_friendlyurls
	where urlid = _urlid;
	
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_friendlyurls_delete (
	int --:urlid $1
) to public;


-- added 2007-02-07

create or replace function mp_friendlyurls_deletebypageid 
(
	varchar(255) --:pageid $1
) returns int4
as '
declare
	_pageid alias for $1;
	_rowcount int4;
begin

	
	delete from mp_friendlyurls
	where realurl like _pageid
	;
	
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_friendlyurls_deletebypageid (
	varchar(255) --:pageid $1
) to public;

-- end added 2007-02-07





select drop_type('mp_friendlyurls_select_one_type');
CREATE TYPE public.mp_friendlyurls_select_one_type as (
	urlid int4,
	siteid int4,
	friendlyurl varchar(255),
	realurl varchar(255),
	ispattern bool
);


select drop_type('mp_friendlyurls_selectbyhost_type');
CREATE TYPE public.mp_friendlyurls_selectbyhost_type as (
	urlid int4,
	siteid int4,
	friendlyurl varchar(255),
	realurl varchar(255),
	ispattern bool
);


select drop_type('mp_friendlyurls_selectbyurl_type');
CREATE TYPE public.mp_friendlyurls_selectbyurl_type as (
	urlid int4,
	siteid int4,
	friendlyurl varchar(255),
	realurl varchar(255),
	ispattern bool
);

create or replace function mp_friendlyurls_selectone (
	int --:urlid $1
) returns setof mp_friendlyurls_select_one_type
as '

select
        urlid,
        siteid,
        friendlyurl,
        realurl,
        ispattern
from
        mp_friendlyurls
        
where
        urlid = $1;'
security definer language sql;
grant execute on function mp_friendlyurls_selectone (
	int --:urlid $1
) to public;


create or replace function mp_friendlyurls_selectbyhost(
	varchar(255) --:hostname $1
) returns setof mp_friendlyurls_selectbyhost_type
as '

select
        urlid,
        siteid,
        friendlyurl,
        realurl,
        ispattern
from
        mp_friendlyurls
where   siteid = coalesce(	(select siteid from mp_sitehosts where hostname = $1 limit 1),
				 (select siteid from mp_sites order by siteid limit 1)
			) ;'	
security definer language sql;
grant execute on function mp_friendlyurls_selectbyhost(
	varchar(255) --:hostname $1
) to public;






create or replace function mp_friendlyurls_selectbyurl(
	varchar(255), --:hostname $1
	varchar(255) --:friendlyurl $2
) returns setof mp_friendlyurls_selectbyurl_type
as '

select
        urlid,
        siteid,
        friendlyurl,
        realurl,
        ispattern
from
        mp_friendlyurls
        
where   friendlyurl = $2
	and siteid = coalesce(	(select siteid from mp_sitehosts where hostname = $1 limit 1),
				 (select siteid from mp_sites order by siteid limit 1)
			) ;'	
security definer language sql;
grant execute on function mp_friendlyurls_selectbyurl(
	varchar(255), --:hostname $1
	varchar(255) --:friendlyurl $2
) to public;



create or replace function mp_friendlyurls_selectbysiteurl(
	int, --:siteid $1
	varchar(255) --:friendlyurl $2
) returns setof mp_friendlyurls_selectbyurl_type
as '

select
        urlid,
        siteid,
        friendlyurl,
        realurl,
        ispattern
from
        mp_friendlyurls
        
where   siteid = $1
	and friendlyurl = $2
;'	
security definer language sql;
grant execute on function mp_friendlyurls_selectbysiteurl(
	int, --:siteid $1
	varchar(255) --:friendlyurl $2
) to public;










create or replace function mp_friendlyurls_insert(
	int, --:siteid $1
	varchar(255), --:friendlyurl $2
	varchar(255), --:realurl $3
	bool --:ispattern $4
) returns int4
as '

insert into 	mp_friendlyurls
(				
                siteid,
                friendlyurl,
                realurl,
                ispattern
) 
values 
(				
                $1, --:siteid
                $2, --:friendlyurl
                $3, --:realurl
                $4 --:ispattern
);

select cast(currval(''mp_friendlyurls_urlid_seq'') as int4);'
security definer language sql;
grant execute on function mp_friendlyurls_insert(
	int, --:siteid $1
	varchar(255), --:friendlyurl $2
	varchar(255), --:realurl $3
	bool --:ispattern $4
) to public;

create or replace function mp_friendlyurls_update(
	int, --:urlid $1
	int, --:siteid $2
	varchar(255), --:friendlyurl $3
	varchar(255), --:realurl $4
	bool --:ispattern $5
) returns int
as '
declare
	_urlid alias for $1;
	_siteid alias for $2;
	_friendlyurl alias for $3;
	_realurl alias for $4;
	_ispattern alias for $5;
	_rowcount int4;
begin

update 		mp_friendlyurls

set
            siteid = _siteid, --:siteid
            friendlyurl = _friendlyurl, --:friendlyurl
            realurl = _realurl, --:realurl
            ispattern = _ispattern --:ispattern
            
where
            urlid = _urlid; --:urlid

GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_friendlyurls_update(
	int, --:urlid $1
	int, --:siteid $2
	varchar(255), --:friendlyurl $3
	varchar(255), --:realurl $4
	bool --:ispattern $5
) to public;



-- End Friendly Urls






-- BlogCategories ---------------------------------------

create or replace function mp_blogcategories_delete 
(
	int --:categoryid $1
) returns int4
as '
declare
	_categoryid alias for $1;
	_rowcount int4;
begin


	delete from mp_blogcategories
	where categoryid = _categoryid;
	
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blogcategories_delete (
	int --:categoryid $1
) to public;


select drop_type('mp_blogcategories_select_one_type');
CREATE TYPE public.mp_blogcategories_select_one_type as (
	categoryid int4,
	moduleid int4,
	category varchar(255)
);


select drop_type('mp_blogcategories_select_bymodule_type');
CREATE TYPE public.mp_blogcategories_select_bymodule_type as (
	categoryid int4,
	moduleid int4,
	category varchar(255),
	postcount bigint
);


create or replace function mp_blogcategories_select_one (
	int --:categoryid $1
) returns setof mp_blogcategories_select_one_type
as '

select
        categoryid,
        moduleid,
        category
from
        mp_blogcategories
        
where
        categoryid = $1;'
security definer language sql;
grant execute on function mp_blogcategories_select_one (
	int --:categoryid $1
) to public;


create or replace function mp_blogcategories_select_bymodule(
	int --:moduleid $1
) returns setof mp_blogcategories_select_bymodule_type
as '

select
        bc.categoryid,
        bc.moduleid,
        bc.category,
        count(bic.itemid) as postcount
from
        mp_blogcategories bc
        
join    mp_blogitemcategories bic
on      bc.categoryid = bic.categoryid
        

where   bc.moduleid = $1 
	

group by bc.categoryid, bc.moduleid, bc.category

order by bc.category;'	
security definer language sql;
grant execute on function mp_blogcategories_select_bymodule(
	int --:moduleid $1
) to public;


create or replace function mp_blogcategories_selectlist_bymodule(
	int --:moduleid $1
) returns setof mp_blogcategories_select_bymodule_type
as '

select
        bc.categoryid,
        bc.moduleid,
        bc.category,
        count(bic.itemid) as postcount
from
        mp_blogcategories bc
        
left outer join    mp_blogitemcategories bic
on      bc.categoryid = bic.categoryid
        

where   bc.moduleid = $1 
	

group by bc.categoryid, bc.moduleid, bc.category

order by bc.category;'	
security definer language sql;
grant execute on function mp_blogcategories_selectlist_bymodule(
	int --:moduleid $1
) to public;


create or replace function mp_blogcategories_insert(
	int, --:moduleid $1
	varchar(255) --:category $2
) returns int4
as '

insert into 	mp_blogcategories
(				
                moduleid,
                category
) 
values 
(				
                $1, --:moduleid
                $2 --:category
);

select cast(currval(''mp_blogcategories_categoryid_seq'') as int4);'
security definer language sql;
grant execute on function mp_blogcategories_insert(
	int, --:moduleid $1
	varchar(255) --:category $2
) to public;

create or replace function mp_blogcategories_update(
	int, --:categoryid $1
	varchar(255) --:category $2
) returns int
as '
declare
	_categoryid alias for $1;
	_category alias for $2;
	_rowcount int4;
begin

update 		mp_blogcategories

set
            category = _category --:category
            
where
            categoryid = _categoryid; --:categoryid

GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blogcategories_update(
	int, --:categoryid $1
	varchar(255) --:category $3
) to public;


create or replace function mp_blogitemcategories_delete 
(
	int --:itemid $1
) returns int4
as '
declare
	_itemid alias for $1;
	_rowcount int4;
begin


	delete from mp_blogitemcategories
	where itemid = _itemid;
	
	GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_blogitemcategories_delete (
	int --:itemid $1
) to public;


create or replace function mp_blogitemcategories_insert(
	int, --:itemid $1
	int --:categoryid $2
) returns int4
as '

insert into 	mp_blogitemcategories
(				
                itemid,
                categoryid
) 
values 
(				
                $1, --:itemid
                $2 --:categoryid
);

select cast(currval(''mp_blogitemcategories_id_seq'') as int4);'
security definer language sql;
grant execute on function mp_blogitemcategories_insert(
	int, --:itemid $1
	int --:categoryid $2
) to public;


select drop_type('mp_blogitemcategories_select_byitem_type');
CREATE TYPE public.mp_blogitemcategories_select_byitem_type as (
	categoryid int4,
	category   varchar(255)
);



create or replace function mp_blogitemcategories_select_byitem(
	int --:moduleid $1
) returns setof mp_blogitemcategories_select_byitem_type
as '

select
        bc.categoryid,
        bc.category
from
        mp_blogitemcategories bic
inner join mp_blogcategories bc
on         bic.categoryid = bc.categoryid
where   itemid = $1

order by bc.category;'
		
		
security definer language sql;
grant execute on function mp_blogitemcategories_select_byitem(
	int --:itemid $1
) to public;



select drop_type('mp_blog_selectbycategory_type');
CREATE TYPE public.mp_blog_selectbycategory_type AS (
        itemid int4 ,
        moduleid int4 ,
        createdbyuser varchar(100),
        createddate timestamp,
        title varchar(100),
        excerpt varchar(512),
        description text,
        startdate timestamp,
        isinnewsletter bool,
        includeinfeed bool,
        commentcount int4 
);


create or replace function mp_blog_selectbycategory
(
	int, --:moduleid $1
	int --:categoryid $2
) returns setof mp_blog_selectbycategory_type 
as '
select	
        b.itemid ,
        b.moduleid ,
        b.createdbyuser ,
        b.createddate ,
        b.title , 
        b.excerpt , 
        b.description , 
        b.startdate , 
        b.isinnewsletter ,
        b.includeinfeed ,
        b.commentcount

from	mp_blogs b

inner join    mp_blogitemcategories bic
on            b.itemid = bic.itemid

where     b.moduleid = $1 and bic.categoryid = $2

order by b.startdate desc ;'
security definer language sql;
grant execute on function mp_blog_selectbycategory
(
	int, --:moduleid $1
	int --:categoryid $2
) to public;



-- End BlogCategories -------------------------------------------------


-- Module Settings 20050614 -------------

create or replace function mp_modulesettings_insert(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255), --:settingvalue $3
	varchar(50), --:controltype $4
	text --:regexvalidationexpression $5
) returns int4
as '
declare
	_moduleid alias for $1;
	_settingname alias for $2;
	_settingvalue alias for $3;
	_controltype alias for $4;
	_regexvalidationexpression alias for $5;
	_rowcount int4;
begin


insert into 	mp_modulesettings
(				
                moduleid,
                settingname,
                settingvalue,
                controltype,
                regexvalidationexpression
) 
values 
(				
                _moduleid, --:moduleid
                _settingname, --:settingname
                _settingvalue, --:settingvalue
                _controltype, --:controltype
                _regexvalidationexpression --:regexvalidationexpression
);

GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modulesettings_insert(
	int, --:moduleid $1
	varchar(50), --:settingname $2
	varchar(255), --:settingvalue $3
	varchar(50), --:controltype $4
	text --:regexvalidationexpression $5
) to public;




select drop_type('mp_blog_selectbypage_type');
CREATE TYPE public.mp_blog_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		commentcount int4,
		title varchar(255) ,
		description text ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_blog_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_blog_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.commentcount,
		gi.title, 
		gi.description, 
		m.moduletitle,
		md.featurename
		
from
		mp_blogs gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate))
		; '
security definer language sql;
grant execute on function mp_blog_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;


-------------------------------------

select drop_type('mp_calendarevents_selectbypage_type');
CREATE TYPE public.mp_calendarevents_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		title varchar(255) ,
		description text ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_calendarevents_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_calendarevents_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.title, 
		gi.description, 
		m.moduletitle,
		md.featurename
		
from
		mp_calendarevents gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate)); '
security definer language sql;
grant execute on function mp_calendarevents_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;


-----------------------------------



select drop_type('mp_galleryimages_selectbypage_type');
CREATE TYPE public.mp_galleryimages_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		caption varchar(255) ,
		description text ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_galleryimages_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_galleryimages_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.caption,
		gi.description,
		m.moduletitle,
		md.featurename
		
from
		mp_galleryimages gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate)); '
security definer language sql;
grant execute on function mp_galleryimages_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;




---------------------------------

select drop_type('mp_htmlcontent_selectbypage_type');
CREATE TYPE public.mp_htmlcontent_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		title varchar(255) ,
		body text ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_htmlcontent_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_htmlcontent_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.title,
		gi.body,
		m.moduletitle,
		md.featurename
		
from
		mp_htmlcontent gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate)); '
security definer language sql;
grant execute on function mp_htmlcontent_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;




---------------------------------

select drop_type('mp_links_selectbypage_type');
CREATE TYPE public.mp_links_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		title varchar(255) ,
		description text ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_links_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_links_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.title, 
		gi.description, 
		m.moduletitle,
		md.featurename
		
from
		mp_links gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate)); '
security definer language sql;
grant execute on function mp_links_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;


---------------------------------------------

select drop_type('mp_sharedfiles_selectbypage_type');
CREATE TYPE public.mp_sharedfiles_selectbypage_type AS (

		itemid int4 ,
		moduleid int4 ,
		friendlyname varchar(255) ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_sharedfiles_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_sharedfiles_selectbypage_type 
as '
select
		gi.itemid,
		gi.moduleid,
		gi.friendlyname, 
		m.moduletitle,
		md.featurename
		
from
		mp_sharedfiles gi
		
JOIN		mp_modules m
ON		gi.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate)); '
security definer language sql;
grant execute on function mp_sharedfiles_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;


---------------------------------------------

select drop_type('mp_forumthreads_selectbypage_type');
CREATE TYPE public.mp_forumthreads_selectbypage_type AS (

		threadid int4 ,
		postid int4 ,
		subject varchar(255) ,
		post text ,
		moduleid int4 ,
		itemid int4 ,
		moduletitle varchar(255) ,
		featurename varchar(255) 
);

create or replace function mp_forumthreads_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) returns setof mp_forumthreads_selectbypage_type 
as '
select
		fp.threadid,
		fp.postid,
		fp.subject,
		fp.post,
		f.moduleid,
		f.itemid,
		m.moduletitle,
		md.featurename
		
from
		mp_forumposts fp
		
JOIN		mp_forumthreads ft
ON		fp.threadid = ft.threadid

JOIN		mp_forums f
ON		f.itemid = ft.forumid
		
JOIN		mp_modules m
ON		f.moduleid = m.moduleid

JOIN		mp_moduledefinitions md
ON		m.moduledefid = md.moduledefid

JOIN		mp_pagemodules pm
ON		pm.moduleid = m.moduleid

JOIN		mp_pages p
ON		p.pageid = pm.pageid
		
where
		p.siteid = $1
		AND pm.pageid = $2
		AND (current_timestamp(3) >= pm.publishbegindate)
		AND ((pm.publishenddate IS NULL) OR (current_timestamp(3) < pm.publishenddate))
		AND fp.approved = true  ; '
security definer language sql;
grant execute on function mp_forumthreads_selectbypage
(
	int, --:siteid $1
	int --:pageid $2
) to public;


---------------------------------------------

-- added 5/6/2006

create or replace function mp_sitepaths_insert
(
	varchar(36), --:pathid $1
	int, --:siteid $2
	varchar(255), --:path $3
	varchar(255) --:loweredpath $4
	
) returns boolean 
as '
insert into 		mp_sitepaths
(
			pathid,
    			siteid,
    			path,
    			loweredpath
	
)
values
(
			$1,
    			$2,
    			$3,
    			$4
			
); 

select true; '
security definer language sql;
grant execute on function mp_sitepaths_insert
(
	varchar(36), --:pathid $1
	int, --:siteid $2
	varchar(255), --:path $3
	varchar(255) --:loweredpath $4
	
) to public;


create or replace function mp_sitepaths_count
(
	int, --:siteid $1
	varchar(255) --:loweredpath $2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepaths
where siteid = $1 and loweredpath = $2; '
security definer language sql;


grant execute on function mp_sitepaths_count
(
	int, --:siteid $1
	varchar(255) --:loweredpath $2
) to public;



select drop_type('mp_sitepaths_getpathidtype');
CREATE TYPE public.mp_sitepaths_getpathidtype AS (

	pathid varchar(36) 
);
create or replace function mp_sitepaths_getpathid
(
   
	int,  --:siteid $1
	varchar(255)  --:loweredpath $2
	

) returns setof mp_sitepaths_getpathidtype 
as '
select
	pathid
from
    mp_sitepaths
where
		siteid = $1
    		and loweredpath = $2 
limit 1; '
security definer language sql;
grant execute on function mp_sitepaths_getpathid
(
   
	int,  --:siteid $1
	varchar(255)  --:loweredpath $2

) to public;


create or replace function mp_sitepersonalizationallusers_countbypath
(
	varchar(36) --:pathid $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationallusers
where pathid = $1 
; '
security definer language sql;


grant execute on function mp_sitepersonalizationallusers_countbypath
(
	varchar(36) --:pathid $1
	
) to public;


create or replace function mp_sitepersonalizationperuser_countbypath
(
	varchar(36), --:pathid $1
	varchar(36) --:userguid $2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
where pathid = $1 and userid = $2
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbypath
(
	varchar(36), --:pathid $1
	varchar(36) --:userguid $2
	
) to public;


create or replace function mp_sitepersonalizationallusers_updatepersonalizationblob
(
	varchar(36), --:pathid $1
	bytea, --:pagesettings $2
	timestamp --:lastupdate $3
	
) returns int4
as '
declare
	_pathid alias for $1;
	_pagesettings alias for $2;
	_lastupdate alias for $3;
	_rowcount int4;
begin

    update 
    mp_sitepersonalizationallusers
    set pagesettings = _pagesettings,
    	lastupdate = _lastupdate
    
where
    pathid = _pathid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitepersonalizationallusers_updatepersonalizationblob
(
	varchar(36), --:pathid $1
	bytea, --:pagesettings $2
	timestamp --:lastupdate $3
	
) to public;

--

create or replace function mp_sitepersonalizationperuser_updatepersonalizationblob
(
	varchar(36), --:userid $1
	varchar(36), --:pathid $2
	bytea, --:pagesettings $3
	timestamp --:lastupdate $4
	
) returns int4
as '
declare
	_userid alias for $1;
	_pathid alias for $2;
	_pagesettings alias for $3;
	_lastupdate alias for $4;
	_rowcount int4;
begin

    update 
    mp_sitepersonalizationperuser
    set pagesettings = _pagesettings,
    	lastupdate = _lastupdate
    
where userid = _userid and
    pathid = _pathid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitepersonalizationperuser_updatepersonalizationblob
(
	varchar(36), --:userid $1
	varchar(36), --:pathid $2
	bytea, --:pagesettings $3
	timestamp --:lastupdate $4
	
) to public;


create or replace function mp_sitepersonalizationallusers_insert
(
	varchar(36), --:pathid $1
	bytea, --:pagesettings $2
	timestamp --:lastupdate $3
	
	
) returns boolean
as '
insert into 		mp_sitepersonalizationallusers
(
			pathid,
    			pagesettings,
    			lastupdate
    		
)
values
(
			$1,
    			$2,
    			$3
			
); 

select true; '
security definer language sql;
grant execute on function mp_sitepersonalizationallusers_insert
(
	varchar(36), --:pathid $1
	bytea, --:pagesettings $2
	timestamp --:lastupdate $3
	
) to public;


create or replace function mp_sitepersonalizationperuser_insert
(
	varchar(36), --:id $1
	varchar(36), --:userid $2
	varchar(36), --:pathid $3
	bytea, --:pagesettings $4
	timestamp --:lastupdate $5
	
	
) returns boolean
as '
insert into 		mp_sitepersonalizationperuser
(
			id,
			userid,
			pathid,
    			pagesettings,
    			lastupdate
    		
)
values
(
			$1,
    			$2,
    			$3,
    			$4,
    			$5
			
); 

select true; '
security definer language sql;
grant execute on function mp_sitepersonalizationperuser_insert
(
	varchar(36), --:id $1
	varchar(36), --:userid $2
	varchar(36), --:pathid $3
	bytea, --:pagesettings $4
	timestamp --:lastupdate $5
	
) to public;


select drop_type('mp_sitepersonalizationallusers_getpersonalizationblobtype');
CREATE TYPE public.mp_sitepersonalizationallusers_getpersonalizationblobtype AS (

	pagesettings bytea 
);
create or replace function mp_sitepersonalizationallusers_getpersonalizationblob
(
	varchar(255)  --:pathid $1
	
) returns setof mp_sitepersonalizationallusers_getpersonalizationblobtype 
as '
select
	pagesettings
from
    mp_sitepersonalizationallusers
where
		pathid = $1
    		
limit 1; '
security definer language sql;
grant execute on function mp_sitepersonalizationallusers_getpersonalizationblob
(
   varchar(255)  --:pathid $1

) to public;



create or replace function mp_sitepersonalizationperuser_deletebypath
(
	varchar(36), --:userid $1
	varchar(36) --:pathid $2
	
) returns int4
as '
declare
	_userid alias for $1;
	_pathid alias for $2;
	_rowcount int4;
begin

    delete from
    mp_sitepersonalizationperuser
    
where userid = _userid and pathid = _pathid ; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_sitepersonalizationperuser_deletebypath
(
	varchar(36), --:userid $1
	varchar(36) --:pathid $2
	
) to public;



select drop_type('mp_sitepersonalizationperuser_getpersonalizationblobtype');
CREATE TYPE public.mp_sitepersonalizationperuser_getpersonalizationblobtype AS (

	pagesettings bytea 
);
create or replace function mp_sitepersonalizationperuser_getpersonalizationblob
(
	varchar(255),  --:userid $1
	varchar(255)  --:pathid $2
	
) returns setof mp_sitepersonalizationperuser_getpersonalizationblobtype 
as '
select
	pagesettings
from
    mp_sitepersonalizationperuser
where	userid = $1 and pathid = $2	
limit 1; '
security definer language sql;
grant execute on function mp_sitepersonalizationperuser_getpersonalizationblob
(
   varchar(255),  --:userid $1
   varchar(255)  --:pathid $2

) to public;



create or replace function mp_sitepersonalizationallusers_countall
(
	
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationallusers
; '
security definer language sql;


grant execute on function mp_sitepersonalizationallusers_countall
(	
) to public;


create or replace function mp_sitepersonalizationallusers_countbypath
(
	varchar(36) --:pathid $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationallusers
where		pathid = $1
; '
security definer language sql;


grant execute on function mp_sitepersonalizationallusers_countbypath
(	
	varchar(36) --:pathid $1
) to public;


create or replace function mp_sitepersonalizationperuser_countall
(
	
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countall
(	
) to public;



create or replace function mp_sitepersonalizationperuser_countinactivesince
(
	timestamp --:sincetime $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_users.lastactivitydate <= $1
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countinactivesince
(	
	timestamp --:sincetime $1
) to public;


create or replace function mp_sitepersonalizationperuser_countbyuser
(
	varchar(36) --:userid $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_users.userguid = $1
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbyuser
(	
	varchar(36) --:userid $1
	
) to public;

create or replace function mp_sitepersonalizationperuser_countbyusersince
(
	varchar(36), --:userid $1
	timestamp --:sincetime $2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_users.userguid = $1 and mp_users.lastactivitydate <= $2
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbyusersince
(	
	varchar(36), --:userid $1
	timestamp --:sincetime $2
) to public;



create or replace function mp_sitepersonalizationperuser_countbypathsince
(
	varchar(36), --:pathid $1
	timestamp --:sincetime $2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_sitepersonalizationperuser.pathid = $1 and mp_users.lastactivitydate <= $2
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbypathsince
(	
	varchar(36), --:pathid $1
	timestamp --:sincetime $2
) to public;




create or replace function mp_sitepersonalizationperuser_countbyuserpathsince
(
	varchar(36), --:userid $1
	varchar(36), --:pathid $2
	timestamp --:sincetime $3
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_users.userid = $1
		and mp_sitepersonalizationperuser.pathid = $2 and mp_users.lastactivitydate <= $3
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbyuserpathsince
(	
	varchar(36), --:userid $1
	varchar(36), --:pathid $2
	timestamp --:sincetime $3
) to public;



create or replace function mp_sitepersonalizationperuser_countbyuserpath
(
	varchar(36), --:userid $1
	varchar(36) --:pathid $2
	
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_sitepersonalizationperuser
join		mp_users
on		mp_users.userguid = mp_sitepersonalizationperuser.userid
where		mp_users.userid = $1
		and mp_sitepersonalizationperuser.pathid = $2 
; '
security definer language sql;


grant execute on function mp_sitepersonalizationperuser_countbyuserpath
(	
	varchar(36), --:userid $1
	varchar(36) --:pathid $2
	
) to public;



-- added 5/24/2006
select drop_type('mp_modules_selectpage_type');
CREATE TYPE public.mp_modules_selectpage_type AS (
	moduleid int4 ,
	moduletitle varchar(255) ,
	featurename varchar(255) ,
	controlsrc varchar(255) ,
	authorizededitroles text,
	createdby varchar(100) ,
	createddate timestamp 
	
);
create or replace function mp_modules_selectpage
(
	int, --:siteid $1
	int, --:pagenumber $2
	int, --:pagesize $3
	bool, --:sortbymoduletype $3
	bool --:sortbyauthor $4
) returns setof mp_modules_selectpage_type 
as '
declare
	_siteid alias for $1;
	_pagenumber alias for $2;
	_pagesize alias for $3;
	_sortbymoduletype alias for $4;
	_sortbyauthor alias for $5;
	 _pagelowerbound int;
	 _pageupperbound int;
	 _totalrows int;
	 _remainder int;
	_rec mp_modules_selectpage_type%ROWTYPE;

begin

_pagelowerbound := (_pagesize * _pagenumber) - _pagesize;
_pageupperbound := _pagelowerbound + _pagesize + 1;

if _sortbymoduletype = true then
for _rec in
	select 
		m.moduleid ,
		m.moduletitle ,
		md.featurename ,
		md.controlsrc ,
		m.authorizededitroles ,
		u.name as createdby,
		m.createddate 
		

	from 		mp_modules m
	join		mp_moduledefinitions md
	on		m.moduledefid = md.moduledefid
	left outer join mp_users u
	on	m.createdbyuserid = u.userid
	where m.siteid = $1 and md.isadmin = false
	order by 	md.featurename, m.moduletitle
	limit 	_pagesize
	offset 	_pagelowerbound
loop
	return next _rec;
end loop;
else
	if _sortbyauthor = true then
	for _rec in
		select 
			m.moduleid ,
			m.moduletitle ,
			md.featurename ,
			md.controlsrc ,
			m.authorizededitroles ,
			u.name as createdby,
			m.createddate 
			
	
		from 		mp_modules m
		join		mp_moduledefinitions md
		on		m.moduledefid = md.moduledefid
		left outer join mp_users u
		on	m.createdbyuserid = u.userid
		where m.siteid = $1 and md.isadmin = false
		order by 	u.name, m.moduletitle
		limit 	_pagesize
		offset 	_pagelowerbound
	loop
		return next _rec;
	end loop;
	else
		
		for _rec in
			select 
				m.moduleid ,
				m.moduletitle ,
				md.featurename ,
				md.controlsrc ,
				m.authorizededitroles ,
				u.name as createdby,
				m.createddate 
				
		
			from 		mp_modules m
			join		mp_moduledefinitions md
			on		m.moduledefid = md.moduledefid
			left outer join mp_users u
			on	m.createdbyuserid = u.userid
			where m.siteid = $1 and md.isadmin = false
			order by 	m.moduletitle, md.featurename
			limit 	_pagesize
			offset 	_pagelowerbound
		loop
			return next _rec;
		end loop;
		
	end if;
end if;

return;
end'
security definer language plpgsql;
grant execute on function mp_modules_selectpage
(
	int, --:siteid $1
	int, --:pagenumber $2
	int, --:pagesize $3
	bool, --:sortbymoduletype $3
	bool --:sortbyauthor $4
) to public;

-- end added 5/24/2006

-- added 6/3/2006

create or replace function mp_webparts_insert(
	varchar(36), --:webpartid $1
	int, --:siteid $2
	varchar(255), --:title $3
	varchar(255), --:description $4
	varchar(255), --:imageurl $5
	varchar(255), --:classname $6
	varchar(255), --:assemblyname $7
	bool, --:availableformypage $8
	bool, --:allowmultipleinstancesonmypage $9
	bool --:availableforcontentsystem $10
) returns int4
as '
declare
_webpartid alias for $1;
_siteid alias for $2;
_title alias for $3;
_description alias for $4;
_imageurl alias for $5;
_classname alias for $6;
_assemblyname alias for $7;
_availableformypage alias for $8;
_allowmultipleinstancesonmypage alias for $9;
_availableforcontentsystem alias for $10;
_rowcount int4;
begin
insert into 	mp_webparts
(			
                webpartid,
                siteid,
                title,
                description,
                imageurl,
                classname,
                assemblyname,
                availableformypage,
                allowmultipleinstancesonmypage,
                availableforcontentsystem
) 
values 
(				
                _webpartid, 
                _siteid, 
                _title, 
                _description, 
                _imageurl, 
                _classname, 
                _assemblyname, 
                _availableformypage, 
                _allowmultipleinstancesonmypage, 
                _availableforcontentsystem 
);
--GET DIAGNOSTICS _rowcount = ROW_COUNT;
--return _rowcount;
SELECT 1;
end'
security definer language plpgsql;
grant execute on function mp_webparts_insert(
	varchar(36), --:webpartid $1
	int, --:siteid $2
	varchar(255), --:title $3
	varchar(255), --:description $4
	varchar(255), --:imageurl $5
	varchar(255), --:classname $6
	varchar(255), --:assemblyname $7
	bool, --:availableformypage $8
	bool, --:allowmultipleinstancesonmypage $9
	bool --:availableforcontentsystem $10
) to public;

create or replace function mp_webparts_update(
	varchar(36), --:webpartid $1
	int, --:siteid $2
	varchar(255), --:title $3
	varchar(255), --:description $4
	varchar(255), --:imageurl $5
	varchar(255), --:classname $6
	varchar(255), --:assemblyname $7
	bool, --:availableformypage $8
	bool, --:allowmultipleinstancesonmypage $9
	bool --:availableforcontentsystem $10
) returns int4
as '
declare
_webpartid alias for $1;
_siteid alias for $2;
_title alias for $3;
_description alias for $4;
_imageurl alias for $5;
_classname alias for $6;
_assemblyname alias for $7;
_availableformypage alias for $8;
_allowmultipleinstancesonmypage alias for $9;
_availableforcontentsystem alias for $10;
_rowcount int4;
begin
update 		mp_webparts
set
            siteid = _siteid, 
            title = _title, 
            description = _description, 
            imageurl = _imageurl, 
            classname = _classname, 
            assemblyname = _assemblyname, 
            availableformypage = _availableformypage, 
            allowmultipleinstancesonmypage = _allowmultipleinstancesonmypage, 
            availableforcontentsystem = _availableforcontentsystem   
where
            webpartid = _webpartid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_webparts_update(
	varchar(36), --:webpartid $1
	int, --:siteid $2
	varchar(255), --:title $3
	varchar(255), --:description $4
	varchar(255), --:imageurl $5
	varchar(255), --:classname $6
	varchar(255), --:assemblyname $7
	bool, --:availableformypage $8
	bool, --:allowmultipleinstancesonmypage $9
	bool --:availableforcontentsystem $10
) to public;


create or replace function mp_webparts_delete 
(
	varchar(36) --:webpartid $1
) returns int4
as '
declare
            _webpartid alias for $1;
			_rowcount int4;
begin
	delete from mp_webparts
	where webpartid = _webpartid;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_webparts_delete (
	varchar(36) --:webpartid $1
) to public;


select drop_type('mp_webparts_select_one_type');
CREATE TYPE public.mp_webparts_select_one_type as (
	webpartid varchar(36),
	siteid int4,
	title varchar(255),
	description varchar(255),
	imageurl varchar(255),
	classname varchar(255),
	assemblyname varchar(255),
	availableformypage bool,
	allowmultipleinstancesonmypage bool,
	availableforcontentsystem bool,
	countofuseonmypage int4
);

create or replace function mp_webparts_select_one (
	varchar(36) --:webpartid $1
) returns setof mp_webparts_select_one_type
as '

select
        webpartid,
        siteid,
        title,
        description,
        imageurl,
        classname,
        assemblyname,
        availableformypage,
        allowmultipleinstancesonmypage,
        availableforcontentsystem,
        countofuseonmypage 
from
        mp_webparts
        
where
        webpartid = $1;'
security definer language sql;
grant execute on function mp_webparts_select_one (
	varchar(36) --:webpartid $1
) to public;

-- end added 6/3/2006


-- added 6/18/2006

create or replace function mp_modules_updatecountofuseonmypage
(
	int, --:moduleid $1
	int --:increment $2
) returns int4
as '
declare
	_moduleid alias for $1;
	_increment alias for $2;
	_rowcount int4;
begin

update
    mp_modules
set
    countofuseonmypage = countofuseonmypage + _increment
where
    moduleid = _moduleid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_modules_updatecountofuseonmypage
(
	int, --:moduleid $1
	int --:increment $2
) to public;


create or replace function mp_userpages_insert(
	varchar(36), --:userpageid $1
	int, --:siteid $2
	varchar(36), --:userguid $3
	varchar(255), --:pagename $4
	varchar(255), --:pagepath $5
	int --:pageorder $6
) returns int4
as '
declare
_userpageid alias for $1;
_siteid alias for $2;
_userguid alias for $3;
_pagename alias for $4;
_pagepath alias for $5;
_pageorder alias for $6;
_rowcount int4;
begin
insert into 	mp_userpages
(			
                userpageid,
                siteid,
                userguid,
                pagename,
                pagepath,
                pageorder
) 
values 
(				
                _userpageid, 
                _siteid, 
                _userguid, 
                _pagename, 
                _pagepath, 
                _pageorder 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userpages_insert(
	varchar(36), --:userpageid $1
	int, --:siteid $2
	varchar(36), --:userguid $3
	varchar(255), --:pagename $4
	varchar(255), --:pagepath $5
	int --:pageorder $6
) to public;


create or replace function mp_userpages_update(
	varchar(36), --:userpageid $1
	varchar(255), --:pagename $2
	int --:pageorder $3
) returns int4
as '
declare
_userpageid alias for $1;
_pagename alias for $2;
_pageorder alias for $3;
_rowcount int4;
begin
update 		mp_userpages
set  
            pagename = _pagename, 
            pageorder = _pageorder 
            
where
            userpageid = _userpageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userpages_update(
	varchar(36), --:userpageid $1
	varchar(255), --:pagename $2
	int --:pageorder $3
) to public;

create or replace function mp_userpages_delete 
(
	varchar(36) --:userpageid $1
) returns int4
as '
declare
_userpageid alias for $1;
_rowcount int4;
begin
	delete from mp_userpages
	where userpageid = _userpageid;
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userpages_delete (
	varchar(36) --:userpageid $1
) to public;


select drop_type('mp_userpages_select_one_type');
CREATE TYPE public.mp_userpages_select_one_type as (
	userpageid varchar(36),
	siteid int4,
	userguid varchar(36),
	pagename varchar(255),
	pagepath varchar(255),
	pageorder int4
);



create or replace function mp_userpages_select_one (
	varchar(36) --:userpageid $1
) returns setof mp_userpages_select_one_type
as '

select
        userpageid,
        siteid,
        userguid,
        pagename,
        pagepath,
        pageorder
from
        mp_userpages
        
where
        userpageid = $1;'
security definer language sql;
grant execute on function mp_userpages_select_one (
	varchar(36) --:userpageid $1
) to public;


select drop_type('mp_userpages_select_byuser_type');
CREATE TYPE public.mp_userpages_select_byuser_type as (
	userpageid varchar(36),
	siteid int4,
	userguid varchar(36),
	pagename varchar(255),
	pagepath varchar(255),
	pageorder int4
);



create or replace function mp_userpages_select_byuser (
	varchar(36) --:userguid $1
) returns setof mp_userpages_select_byuser_type
as '

select
        userpageid,
        siteid,
        userguid,
        pagename,
        pagepath,
        pageorder
from
        mp_userpages
        
where
        userguid = $1;'
security definer language sql;
grant execute on function mp_userpages_select_byuser (
	varchar(36) --:userguid $1
) to public;


create or replace function mp_userpages_getnextpageorder
(
	varchar(36) --:userguid $1
) returns int4
as '
select	coalesce(max(pageorder), -1) + 2
from		mp_userpages
where	userguid = $1; '
security definer language sql;
grant execute on function mp_userpages_getnextpageorder
(
	varchar(36) --:userguid $1
) to public;


create or replace function mp_userpages_updatepageorder(
	varchar(36), --:userpageid $1
	int --:pageorder $2
) returns int4
as '

declare
            _userpageid alias for $1;
            _pageorder alias for $2;
			_rowcount int4;
begin
update 		mp_userpages

set
          
            pageorder = _pageorder 
            
where
            userpageid = _userpageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userpages_updatepageorder(
	varchar(36), --:userpageid $1
	int --:pageorder $2
) to public;


select drop_type('mp_webparts_select_bysite_type');
CREATE TYPE public.mp_webparts_select_bysite_type as (
	webpartid varchar(36),
	siteid int4,
	title varchar(255),
	description varchar(255),
	imageurl varchar(255),
	classname varchar(255),
	assemblyname varchar(255),
	availableformypage bool,
	allowmultipleinstancesonmypage bool,
	availableforcontentsystem bool,
	countofuseonmypage int4
);

create or replace function mp_webparts_select_bysite (
	int --:siteid $1
) returns setof mp_webparts_select_bysite_type
as '

select
        webpartid,
        siteid,
        title,
        description,
        imageurl,
        classname,
        assemblyname,
        availableformypage,
        allowmultipleinstancesonmypage,
        availableforcontentsystem,
        countofuseonmypage 
from
        mp_webparts
        
where
        siteid = $1;'
security definer language sql;
grant execute on function mp_webparts_select_bysite (
	int --:siteid $1
) to public;


select drop_type('mp_webparts_selectpage_type');
CREATE TYPE public.mp_webparts_selectpage_type AS (
	webpartid varchar(36),
	siteid int4,
	title varchar(255),
	description varchar(255),
	imageurl varchar(255),
	classname varchar(255),
	assemblyname varchar(255),
	availableformypage bool,
	allowmultipleinstancesonmypage bool,
	availableforcontentsystem bool,
	countofuseonmypage int4
	
);
create or replace function mp_webparts_selectpage
(
	int, --:siteid $1
	int, --:pagenumber $2
	int, --:pagesize $3
	bool, --:sortbyclassname $3
	bool --:sortbyassemblyname $4
) returns setof mp_webparts_selectpage_type 
as '
declare
	_siteid alias for $1;
	_pagenumber alias for $2;
	_pagesize alias for $3;
	_sortbyclassname alias for $4;
	_sortbyassemblyname alias for $5;
	 _pagelowerbound int;
	 _pageupperbound int;
	 _totalrows int;
	 _remainder int;
	_rec mp_webparts_selectpage_type%ROWTYPE;

begin

_pagelowerbound := (_pagesize * _pagenumber) - _pagesize;
_pageupperbound := _pagelowerbound + _pagesize + 1;

if _sortbyclassname = true then
for _rec in
	select 
		webpartid,
		siteid,
		title,
		description,
		imageurl,
		classname,
		assemblyname,
		availableformypage,
		allowmultipleinstancesonmypage,
		availableforcontentsystem,
        	countofuseonmypage 
		

	from 		mp_webparts 
	
	where siteid = $1 
	order by 	classname, title
	limit 	_pagesize
	offset 	_pagelowerbound
loop
	return next _rec;
end loop;
else
	if _sortbyassemblyname = true then
	for _rec in
		select 
			webpartid,
			siteid,
			title,
			description,
			imageurl,
			classname,
			assemblyname,
			availableformypage,
			allowmultipleinstancesonmypage,
			availableforcontentsystem,
        		countofuseonmypage 
			
	
		from 		mp_webparts 
		
		where siteid = $1 
		order by 	assemblyname, title
		limit 	_pagesize
		offset 	_pagelowerbound
	loop
		return next _rec;
	end loop;
	else
		
		for _rec in
			select 
			webpartid,
			siteid,
			title,
			description,
			imageurl,
			classname,
			assemblyname,
			availableformypage,
			allowmultipleinstancesonmypage,
			availableforcontentsystem,
        		countofuseonmypage 
				
		
			from 		mp_webparts 
			
			where siteid = $1 
			order by 	title, classname
			limit 	_pagesize
			offset 	_pagelowerbound
		loop
			return next _rec;
		end loop;
		
	end if;
end if;

return;
end'
security definer language plpgsql;
grant execute on function mp_webparts_selectpage
(
	int, --:siteid $1
	int, --:pagenumber $2
	int, --:pagesize $3
	bool, --:sortbyclassname $3
	bool --:sortbyassemblyname $4
) to public;

create or replace function mp_webparts_count
(
	int --:siteid $1
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_webparts
where siteid = $1; '
security definer language sql;

grant execute on function mp_webparts_count
(
	int --:siteid $1
) to public;


create or replace function mp_webparts_exists
(
	int, --:siteid $1
	varchar(255), --:classname $2
	varchar(255) --:assemblyname $3
) returns int4
as '
select	cast(count(*) as int4)
from		mp_webparts
where	siteid = $1 AND classname = $2 AND assemblyname = $3; '
security definer language sql;
grant execute on function mp_webparts_exists
(
	int, --:siteid $1
	varchar(255), --:classname $2
	varchar(255) --:assemblyname $3
) to public;



select drop_type('mp_webparts_select_formypage_type');
CREATE TYPE public.mp_webparts_select_formypage_type as (
	moduleid int4,
	siteid int4,
	moduledefid int4,
	moduletitle varchar(255),
	allowmultipleinstancesonmypage bool,
	countofuseonmypage int4,
	moduleicon varchar(255),
	featureicon varchar(255),
	featurename varchar(255),
	isassembly bool,
	webpartid varchar(36)
);

create or replace function mp_webparts_select_formypage (
	int --:siteid $1
) returns setof mp_webparts_select_formypage_type
as '

SELECT  		m.moduleid,
				m.siteid,
				m.moduledefid,
				m.moduletitle,
				m.allowmultipleinstancesonmypage,
				m.countofuseonmypage ,
				m.icon As moduleicon,
				md.icon As featureicon,
				md.featurename,
				false As isassembly,
				'''' As webpartid
				
FROM
    			mp_modules m
  
INNER JOIN
    			mp_moduledefinitions md
ON 			m.moduledefid = md.moduledefid

WHERE   
    			m.siteid = $1
				AND m.availableformypage = true

UNION

SELECT
				-1 As moduleID,
				w.siteID,
				0 As muduledefid,
				w.title As moduletitle,
				w.allowmultipleinstancesonmypage,
				w.countofuseonmypage ,
				w.imageurl As moduleicon,
				w.imageurl As featureicon,
				w.description As featurename,
				true As isassembly,
				w.webpartid

FROM			mp_WebParts w

WHERE			w.siteid = $1
				AND w.availableformypage = true
				
ORDER BY
    			moduletitle;'
security definer language sql;
grant execute on function mp_webparts_select_formypage (
	int --:siteid $1
) to public;



create or replace function mp_webparts_updatecountofuseonmypage
(
	varchar(36), --:webpartid $1
	int --:increment $2
) returns int4
as '
declare
	_webpartid alias for $1;
	_increment alias for $2;
	_rowcount int4;
begin

update
    mp_webparts
set
    countofuseonmypage = countofuseonmypage + _increment
where
    webpartid = _webpartid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_webparts_updatecountofuseonmypage
(
	varchar(36), --:webpartid $1
	int --:increment $2
) to public;






-- end aded 6/18/2006

-- added 6/27/2006

create or replace function mp_forum_delete
(
	int --:itemid $1
) returns int4 
as '
declare
	_itemid alias for $1;
	_rowcount int;
begin


delete from 
    mp_forums
where
    itemid = _itemid;
    
GET DIAGNOSTICS _rowcount = ROW_COUNT;

return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_forum_delete
(
	int --:itemid $1
) to public;


-- end added 6/27/2006



-- added 8/2/2006
/*
create or replace function mp_privatemessages_insert(
	varchar(36), --:messageid $1
	varchar(36), --:fromuser $2
	varchar(36), --:priorityid $3
	varchar(255), --:subject $4
	text, --:body $5
	text, --:tocsvlist $6
	text, --:cccsvlist $7
	text, --:bcccsvlist $8
	text, --:tocsvlabels $9
	text, --:cccsvlabels $10
	text, --:bcccsvlabels $11
	date, --:createddate $12
	date --:sentdate $13
) returns int4
as '
declare
            _messageid alias for $1;
            _fromuser alias for $2;
            _priorityid alias for $3;
            _subject alias for $4;
            _body alias for $5;
            _tocsvlist alias for $6;
            _cccsvlist alias for $7;
            _bcccsvlist alias for $8;
            _tocsvlabels alias for $9;
            _cccsvlabels alias for $10;
            _bcccsvlabels alias for $11;
            _createddate alias for $12;
            _sentdate alias for $13;
			_rowcount int4;
begin

insert into 	mp_privatemessages
(			
                messageid,
                fromuser,
                priorityid,
                subject,
                body,
                tocsvlist,
                cccsvlist,
                bcccsvlist,
                tocsvlabels,
                cccsvlabels,
                bcccsvlabels,
                createddate,
                sentdate
) 
values 
(				
                _messageid, 
                _fromuser, 
                _priorityid, 
                _subject, 
                _body, 
                _tocsvlist, 
                _cccsvlist, 
                _bcccsvlist, 
                _tocsvlabels, 
                _cccsvlabels, 
                _bcccsvlabels, 
                _createddate, 
                _sentdate 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessages_insert(
	varchar(36), --:messageid $1
	varchar(36), --:fromuser $2
	varchar(36), --:priorityid $3
	varchar(255), --:subject $4
	text, --:body $5
	text, --:tocsvlist $6
	text, --:cccsvlist $7
	text, --:bcccsvlist $8
	text, --:tocsvlabels $9
	text, --:cccsvlabels $10
	text, --:bcccsvlabels $11
	date, --:createddate $12
	date --:sentdate $13
) to public;


create or replace function mp_privatemessages_update(
	varchar(36), --:messageid $1
	varchar(36), --:fromuser $2
	varchar(36), --:priorityid $3
	varchar(255), --:subject $4
	text, --:body $5
	text, --:tocsvlist $6
	text, --:cccsvlist $7
	text, --:bcccsvlist $8
	text, --:tocsvlabels $9
	text, --:cccsvlabels $10
	text, --:bcccsvlabels $11
	date, --:createddate $12
	date --:sentdate $13
) returns int4
as '

declare
            _messageid alias for $1;
            _fromuser alias for $2;
            _priorityid alias for $3;
            _subject alias for $4;
            _body alias for $5;
            _tocsvlist alias for $6;
            _cccsvlist alias for $7;
            _bcccsvlist alias for $8;
            _tocsvlabels alias for $9;
            _cccsvlabels alias for $10;
            _bcccsvlabels alias for $11;
            _createddate alias for $12;
            _sentdate alias for $13;
			_rowcount int4;
begin
update 		mp_privatemessages

set
            fromuser = _fromuser, 
            priorityid = _priorityid, 
            subject = _subject, 
            body = _body, 
            tocsvlist = _tocsvlist, 
            cccsvlist = _cccsvlist, 
            bcccsvlist = _bcccsvlist, 
            tocsvlabels = _tocsvlabels, 
            cccsvlabels = _cccsvlabels, 
            bcccsvlabels = _bcccsvlabels, 
            createddate = _createddate, 
            sentdate = _sentdate 
            
where
            messageid = _messageid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessages_update(
	varchar(36), --:messageid $1
	varchar(36), --:fromuser $2
	varchar(36), --:priorityid $3
	varchar(255), --:subject $4
	text, --:body $5
	text, --:tocsvlist $6
	text, --:cccsvlist $7
	text, --:bcccsvlist $8
	text, --:tocsvlabels $9
	text, --:cccsvlabels $10
	text, --:bcccsvlabels $11
	date, --:createddate $12
	date --:sentdate $13
) to public;



create or replace function mp_privatemessages_delete 
(
	varchar(36) --:messageid $1
) returns int4
as '
declare
            _messageid alias for $1;
			_rowcount int4;
begin
	delete from mp_privatemessages
	where messageid = _messageid;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessages_delete (
	varchar(36) --:messageid $1
) to public;



select drop_type('mp_privatemessages_select_one_type');
CREATE TYPE public.mp_privatemessages_select_one_type as (
	messageid varchar(36),
	fromuser varchar(36),
	priorityid varchar(36),
	subject varchar(255),
	body text,
	tocsvlist text,
	cccsvlist text,
	bcccsvlist text,
	tocsvlabels text,
	cccsvlabels text,
	bcccsvlabels text,
	createddate date,
	sentdate date
);



create or replace function mp_privatemessages_select_one (
	varchar(36) --:messageid $1
) returns setof mp_privatemessages_select_one_type
as '

select
        messageid,
        fromuser,
        priorityid,
        subject,
        body,
        tocsvlist,
        cccsvlist,
        bcccsvlist,
        tocsvlabels,
        cccsvlabels,
        bcccsvlabels,
        createddate,
        sentdate
from
        mp_privatemessages
        
where
        messageid = $1;'
security definer language sql;
grant execute on function mp_privatemessages_select_one (
	varchar(36) --:messageid $1
) to public;


	
select drop_type('mp_privatemessages_select_all_type');
CREATE TYPE public.mp_privatemessages_select_all_type as (
	messageid varchar(36),
	fromuser varchar(36),
	priorityid varchar(36),
	subject varchar(255),
	body text,
	tocsvlist text,
	cccsvlist text,
	bcccsvlist text,
	tocsvlabels text,
	cccsvlabels text,
	bcccsvlabels text,
	createddate date,
	sentdate date
);


create or replace function mp_privatemessages_select_all(
	int --:moduleid $1
) returns setof mp_privatemessages_select_all_type
as '

select
        messageid,
        fromuser,
        priorityid,
        subject,
        body,
        tocsvlist,
        cccsvlist,
        bcccsvlist,
        tocsvlabels,
        cccsvlabels,
        bcccsvlabels,
        createddate,
        sentdate
from
        mp_privatemessages
where   moduleid = $1;'
		
		
security definer language sql;
grant execute on function mp_privatemessages_select_all(
	int --:moduleid $1
) to public;

create or replace function mp_privatemessagepriority_insert(
	varchar(36), --:priorityid $1
	varchar(50) --:priority $2
) returns int4
as '
declare
            _priorityid alias for $1;
            _priority alias for $2;
			_rowcount int4;
begin

insert into 	mp_privatemessagepriority
(			
                priorityid,
                priority
) 
values 
(				
                _priorityid, 
                _priority 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessagepriority_insert(
	varchar(36), --:priorityid $1
	varchar(50) --:priority $2
) to public;


create or replace function mp_privatemessagepriority_update(
	varchar(36), --:priorityid $1
	varchar(50) --:priority $2
) returns int4
as '

declare
            _priorityid alias for $1;
            _priority alias for $2;
			_rowcount int4;
begin
update 		mp_privatemessagepriority

set
            priority = _priority 
            
where
            priorityid = _priorityid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessagepriority_update(
	varchar(36), --:priorityid $1
	varchar(50) --:priority $2
) to public;



create or replace function mp_privatemessagepriority_delete 
(
	varchar(36) --:priorityid $1
) returns int4
as '
declare
            _priorityid alias for $1;
			_rowcount int4;
begin
	delete from mp_privatemessagepriority
	where priorityid = _priorityid;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessagepriority_delete (
	varchar(36) --:priorityid $1
) to public;



select drop_type('mp_privatemessagepriority_select_one_type');
CREATE TYPE public.mp_privatemessagepriority_select_one_type as (
	priorityid varchar(36),
	priority varchar(50)
);



create or replace function mp_privatemessagepriority_select_one (
	varchar(36) --:priorityid $1
) returns setof mp_privatemessagepriority_select_one_type
as '

select
        priorityid,
        priority
from
        mp_privatemessagepriority
        
where
        priorityid = $1;'
security definer language sql;
grant execute on function mp_privatemessagepriority_select_one (
	varchar(36) --:priorityid $1
) to public;


	
select drop_type('mp_privatemessagepriority_select_all_type');
CREATE TYPE public.mp_privatemessagepriority_select_all_type as (
	priorityid varchar(36),
	priority varchar(50)
);


create or replace function mp_privatemessagepriority_select_all(
	int --:moduleid $1
) returns setof mp_privatemessagepriority_select_all_type
as '

select
        priorityid,
        priority
from
        mp_privatemessagepriority
where   moduleid = $1;'
		
		
security definer language sql;
grant execute on function mp_privatemessagepriority_select_all(
	int --:moduleid $1
) to public;

create or replace function mp_privatemessageattachments_insert(
	varchar(36), --:attachmentid $1
	varchar(36), --:messageid $2
	varchar(255), --:originalfilename $3
	varchar(50), --:serverfilename $4
	date --:createddate $5
) returns int4
as '
declare
            _attachmentid alias for $1;
            _messageid alias for $2;
            _originalfilename alias for $3;
            _serverfilename alias for $4;
            _createddate alias for $5;
			_rowcount int4;
begin

insert into 	mp_privatemessageattachments
(			
                attachmentid,
                messageid,
                originalfilename,
                serverfilename,
                createddate
) 
values 
(				
                _attachmentid, 
                _messageid, 
                _originalfilename, 
                _serverfilename, 
                _createddate 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessageattachments_insert(
	varchar(36), --:attachmentid $1
	varchar(36), --:messageid $2
	varchar(255), --:originalfilename $3
	varchar(50), --:serverfilename $4
	date --:createddate $5
) to public;


create or replace function mp_privatemessageattachments_update(
	varchar(36), --:attachmentid $1
	varchar(36), --:messageid $2
	varchar(255), --:originalfilename $3
	varchar(50), --:serverfilename $4
	date --:createddate $5
) returns int4
as '

declare
            _attachmentid alias for $1;
            _messageid alias for $2;
            _originalfilename alias for $3;
            _serverfilename alias for $4;
            _createddate alias for $5;
			_rowcount int4;
begin
update 		mp_privatemessageattachments

set
            messageid = _messageid, 
            originalfilename = _originalfilename, 
            serverfilename = _serverfilename, 
            createddate = _createddate 
            
where
            attachmentid = _attachmentid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessageattachments_update(
	varchar(36), --:attachmentid $1
	varchar(36), --:messageid $2
	varchar(255), --:originalfilename $3
	varchar(50), --:serverfilename $4
	date --:createddate $5
) to public;



create or replace function mp_privatemessageattachments_delete 
(
	varchar(36) --:attachmentid $1
) returns int4
as '
declare
            _attachmentid alias for $1;
			_rowcount int4;
begin
	delete from mp_privatemessageattachments
	where attachmentid = _attachmentid;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_privatemessageattachments_delete (
	varchar(36) --:attachmentid $1
) to public;


select drop_type('mp_privatemessageattachments_select_one_type');
CREATE TYPE public.mp_privatemessageattachments_select_one_type as (
	attachmentid varchar(36),
	messageid varchar(36),
	originalfilename varchar(255),
	serverfilename varchar(50),
	createddate date
);



create or replace function mp_privatemessageattachments_select_one (
	varchar(36) --:attachmentid $1
) returns setof mp_privatemessageattachments_select_one_type
as '

select
        attachmentid,
        messageid,
        originalfilename,
        serverfilename,
        createddate
from
        mp_privatemessageattachments
        
where
        attachmentid = $1;'
security definer language sql;
grant execute on function mp_privatemessageattachments_select_one (
	varchar(36) --:attachmentid $1
) to public;


	
select drop_type('mp_privatemessageattachments_select_all_type');
CREATE TYPE public.mp_privatemessageattachments_select_all_type as (
	attachmentid varchar(36),
	messageid varchar(36),
	originalfilename varchar(255),
	serverfilename varchar(50),
	createddate date
);


create or replace function mp_privatemessageattachments_select_all(
	int --:moduleid $1
) returns setof mp_privatemessageattachments_select_all_type
as '

select
        attachmentid,
        messageid,
        originalfilename,
        serverfilename,
        createddate
from
        mp_privatemessageattachments
where   moduleid = $1;'
		
		
security definer language sql;
grant execute on function mp_privatemessageattachments_select_all(
	int --:moduleid $1
) to public;

*/
-- end 8/2/2006

-- added 12/3/2006


create or replace function mp_users_countbyregistrationdaterange
(
	int, --:siteid $1
	timestamp, --:begindate $2
	timestamp --:enddate $3
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_users
where siteid = $1
and datecreated >= $2
and datecreated < $3
; '
security definer language sql;


grant execute on function mp_users_countbyregistrationdaterange
(
	int, --:siteid $1
	timestamp, --:begindate $2
	timestamp --:enddate $3
) to public;


create or replace function mp_users_getnewestid
(
	int --:siteid $1
) returns int4
as '
select  	cast(max(userid) as int4)
from		mp_users
where siteid = $1

; '
security definer language sql;


grant execute on function mp_users_getnewestid
(
	int --:siteid $1
) to public;


create or replace function mp_users_gettop50usersonlinesince
(
    
	int, --:siteid $1
	timestamp --:sincetime $2
) returns setof mp_users 
as '
select	*
from
    mp_users
where
	siteid = $1
   	and lastactivitydate > $2
   	order by lastactivitydate desc
   	limit 50
   	; '
security definer language sql;
grant execute on function mp_users_gettop50usersonlinesince
(
    
	int, --:siteid $1
	timestamp --:sincetime $2
) to public;


create or replace function mp_users_countbyfirstletter
(
	int, --:siteid $1
	varchar(1) --:usernamebeginswith$2
) returns int4
as '
select  	cast(count(*) as int4)
from		mp_users
where siteid = $1
and	($2 is null 
		or $2 = ''''
		or substring(name from 1 for 1) = $2)

; '
security definer language sql;


grant execute on function mp_users_countbyfirstletter
(
	int, --:siteid $1
	varchar(1) --:usernamebeginswith$2
) to public;

-- end added 12/3/2006


-- added 2007-01-04

create or replace function mp_userproperties_propertyexists
(
	varchar(36), --:userguid $1
	varchar(255) --:propertyname $2
) returns int4
as '
select	cast(count(*) as int4)
from		mp_userproperties
where	userguid = $1 AND propertyname = $2; '
security definer language sql;
grant execute on function mp_userproperties_propertyexists
(
	varchar(36), --:userguid $1
	varchar(255) --:propertyname $2
) to public;


select drop_type('mp_userproperties_select_type');
CREATE TYPE public.mp_userproperties_select_type as (
	propertyid varchar(36),
	userguid varchar(36),
	propertyname varchar(255),
	propertyvaluestring text,
	propertyvaluebinary bytea,
	lastupdateddate date,
	islazyloaded bool
);

create or replace function mp_userproperties_select_byuser (
	varchar(36) --:userguid $1
) returns setof mp_userproperties_select_type
as '

select
        propertyid,
        userguid,
        propertyname,
        propertyvaluestring,
        propertyvaluebinary,
        lastupdateddate,
        islazyloaded
from
        mp_userproperties
        
where
        userguid = $1 and islazyloaded = false
 ;'
security definer language sql;
grant execute on function mp_userproperties_select_byuser (
	varchar(36) --:userguid $1
) to public;



create or replace function mp_userproperties_select_one (
	varchar(36), --:userguid $1
	varchar(255) --:propertyname $2
) returns setof mp_userproperties_select_type
as '

select
        propertyid,
        userguid,
        propertyname,
        propertyvaluestring,
        propertyvaluebinary,
        lastupdateddate,
        islazyloaded
from
        mp_userproperties
        
where
        userguid = $1 and propertyname = $2
        limit 1 ;'
security definer language sql;
grant execute on function mp_userproperties_select_one (
	varchar(36), --:userguid $1
	varchar(255) --:propertyname $2
) to public;


create or replace function mp_userproperties_insert(
	varchar(36), --:propertyid $1
	varchar(36), --:userguid $2
	varchar(255), --:propertyname $3
	text, --:propertyvaluestring $4
	bytea, --:propertyvaluebinary $5
	date, --:lastupdateddate $6
	bool --:islazyloaded $7
) returns int4
as '
declare
            _propertyid alias for $1;
            _userguid alias for $2;
            _propertyname alias for $3;
            _propertyvaluestring alias for $4;
            _propertyvaluebinary alias for $5;
            _lastupdateddate alias for $6;
            _islazyloaded alias for $7;
			_rowcount int4;
begin

insert into 	mp_userproperties
(			
                propertyid,
                userguid,
                propertyname,
                propertyvaluestring,
                propertyvaluebinary,
                lastupdateddate,
                islazyloaded
) 
values 
(				
                _propertyid, 
                _userguid, 
                _propertyname, 
                _propertyvaluestring, 
                _propertyvaluebinary, 
                _lastupdateddate, 
                _islazyloaded 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userproperties_insert(
	varchar(36), --:propertyid $1
	varchar(36), --:userguid $2
	varchar(255), --:propertyname $3
	text, --:propertyvaluestring $4
	bytea, --:propertyvaluebinary $5
	date, --:lastupdateddate $6
	bool --:islazyloaded $7
) to public;


create or replace function mp_userproperties_update(
	varchar(36), --:userguid $1
	varchar(255), --:propertyname $2
	text, --:propertyvaluestring $3
	bytea, --:propertyvaluebinary $4
	date, --:lastupdateddate $5
	bool --:islazyloaded $6
) returns int4
as '

declare
            _userguid alias for $1;
            _propertyname alias for $2;
            _propertyvaluestring alias for $3;
            _propertyvaluebinary alias for $4;
            _lastupdateddate alias for $5;
            _islazyloaded alias for $6;
			_rowcount int4;
begin
update 		mp_userproperties

set
            propertyvaluestring = _propertyvaluestring, 
            propertyvaluebinary = _propertyvaluebinary, 
            lastupdateddate = _lastupdateddate, 
            islazyloaded = _islazyloaded 
            
where
            userguid = _userguid and
            propertyname = _propertyname
            ; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_userproperties_update(
	varchar(36), --:userguid $1
	varchar(255), --:propertyname $2
	text, --:propertyvaluestring $3
	bytea, --:propertyvaluebinary $4
	date, --:lastupdateddate $5
	bool --:islazyloaded $6
) to public;


-- end added 2007-01-04

-- added 2007-01-30

create or replace function mp_schemaversion_insert(
	varchar(36), --:applicationid $1
	varchar(255), --:applicationname $2
	int, --:major $3
	int, --:minor $4
	int, --:build $5
	int --:revision $6
) returns int4
as '
declare
            _applicationid alias for $1;
            _applicationname alias for $2;
            _major alias for $3;
            _minor alias for $4;
            _build alias for $5;
            _revision alias for $6;
			_rowcount int4;
begin

insert into 	mp_schemaversion
(			
                applicationid,
                applicationname,
                major,
                minor,
                build,
                revision
) 
values 
(				
                _applicationid, 
                _applicationname, 
                _major, 
                _minor, 
                _build, 
                _revision 
);
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_schemaversion_insert(
	varchar(36), --:applicationid $1
	varchar(255), --:applicationname $2
	int, --:major $3
	int, --:minor $4
	int, --:build $5
	int --:revision $6
) to public;


create or replace function mp_schemaversion_update(
	varchar(36), --:applicationid $1
	varchar(255), --:applicationname $2
	int, --:major $3
	int, --:minor $4
	int, --:build $5
	int --:revision $6
) returns int4
as '

declare
            _applicationid alias for $1;
            _applicationname alias for $2;
            _major alias for $3;
            _minor alias for $4;
            _build alias for $5;
            _revision alias for $6;
			_rowcount int4;
begin
update 		mp_schemaversion

set
            applicationname = _applicationname, 
            major = _major, 
            minor = _minor, 
            build = _build, 
            revision = _revision 
            
where
            applicationid = _applicationid; 
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_schemaversion_update(
	varchar(36), --:applicationid $1
	varchar(255), --:applicationname $2
	int, --:major $3
	int, --:minor $4
	int, --:build $5
	int --:revision $6
) to public;


create or replace function mp_schemaversion_delete 
(
	varchar(36) --:applicationid $1
) returns int4
as '
declare
            _applicationid alias for $1;
			_rowcount int4;
begin
	delete from mp_schemaversion
	where applicationid = _applicationid;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_schemaversion_delete (
	varchar(36) --:applicationid $1
) to public;


select drop_type('mp_schemaversion_select_one_type');
CREATE TYPE public.mp_schemaversion_select_one_type as (
	applicationid varchar(36),
	applicationname varchar(255),
	major int4,
	minor int4,
	build int4,
	revision int4
);



create or replace function mp_schemaversion_select_one (
	varchar(36) --:applicationid $1
) returns setof mp_schemaversion_select_one_type
as '

select
        applicationid,
        applicationname,
        major,
        minor,
        build,
        revision
from
        mp_schemaversion
        
where
        applicationid = $1;'
security definer language sql;
grant execute on function mp_schemaversion_select_one (
	varchar(36) --:applicationid $1
) to public;

select drop_type('mp_schemaversion_select_all_type');
CREATE TYPE public.mp_schemaversion_select_all_type as (
	applicationid varchar(36),
	applicationname varchar(255),
	major int4,
	minor int4,
	build int4,
	revision int4
);


create or replace function mp_schemaversion_select_all(
) returns setof mp_schemaversion_select_all_type
as '

select
        applicationid,
        applicationname,
        major,
        minor,
        build,
        revision
from
        mp_schemaversion
;'
		
		
security definer language sql;
grant execute on function mp_schemaversion_select_all(
) to public;


create or replace function mp_schemascripthistory_insert(
	varchar(36), --:applicationid $1
	varchar(255), --:scriptfile $2
	timestamp, --:runtime $3
	bool, --:erroroccurred $4
	text, --:errormessage $5
	text --:scriptbody $6
) returns int4
as '

insert into 	mp_schemascripthistory
(				
                applicationid,
                scriptfile,
                runtime,
                erroroccurred,
                errormessage,
                scriptbody
) 
values 
(				
                $1, --:applicationid
                $2, --:scriptfile
                $3, --:runtime
                $4, --:erroroccurred
                $5, --:errormessage
                $6 --:scriptbody
);
select cast(currval(''mp_schemascripthistoryid_seq'') as int4);'
security definer language sql;
grant execute on function mp_schemascripthistory_insert(
	varchar(36), --:applicationid $1
	varchar(255), --:scriptfile $2
	timestamp, --:runtime $3
	bool, --:erroroccurred $4
	text, --:errormessage $5
	text --:scriptbody $6
) to public;


create or replace function mp_schemascripthistory_delete 
(
	int --:id $1
) returns int4
as '
declare
            _id alias for $1;
			_rowcount int4;
begin
	delete from mp_schemascripthistory
	where id = _id;
	
GET DIAGNOSTICS _rowcount = ROW_COUNT;
return _rowcount;
end'
security definer language plpgsql;
grant execute on function mp_schemascripthistory_delete (
	int --:id $1
) to public;

select drop_type('mp_schemascripthistory_select_one_type');
CREATE TYPE public.mp_schemascripthistory_select_one_type as (
	id int4,
	applicationid varchar(36),
	scriptfile varchar(255),
	runtime timestamp,
	erroroccurred bool,
	errormessage text,
	scriptbody text
);

create or replace function mp_schemascripthistory_select_one (
	int --:id $1
) returns setof mp_schemascripthistory_select_one_type
as '

select
        id,
        applicationid,
        scriptfile,
        runtime,
        erroroccurred,
        errormessage,
        scriptbody
from
        mp_schemascripthistory
        
where
        id = $1;'
security definer language sql;
grant execute on function mp_schemascripthistory_select_one (
	int --:id $1
) to public;

create or replace function mp_schemascripthistory_select_byapp (
	varchar(36) --:applicationid $1
) returns setof mp_schemascripthistory_select_one_type
as '

select
        id,
        applicationid,
        scriptfile,
        runtime,
        erroroccurred,
        errormessage,
        scriptbody
from
        mp_schemascripthistory
        
where
        applicationid = $1
        and erroroccurred = false
        
order by id
        ;'
security definer language sql;
grant execute on function mp_schemascripthistory_select_byapp (
	varchar(36) --:applicationid $1
) to public;

create or replace function mp_schemascripthistory_select_errorsbyapp (
	varchar(36) --:applicationid $1
) returns setof mp_schemascripthistory_select_one_type
as '

select
        id,
        applicationid,
        scriptfile,
        runtime,
        erroroccurred,
        errormessage,
        scriptbody
from
        mp_schemascripthistory
        
where
        applicationid = $1
        and erroroccurred = true
        
order by id
        ;'
security definer language sql;
grant execute on function mp_schemascripthistory_select_errorsbyapp (
	varchar(36) --:applicationid $1
) to public;

create or replace function mp_schemascripthistory_exists
(
	varchar(36), --:applicationid $1
	varchar(255) --:scriptfile $2
) returns int4
as '
select	cast(count(*) as int4)
from		mp_schemascripthistory
where	applicationid = $1 AND scriptfile = $2; '
security definer language sql;
grant execute on function mp_schemascripthistory_exists
(
	varchar(36), --:applicationid $1
	varchar(255) --:scriptfile $2
) to public;








-- end added 2007-01-30







-- Keep this at the bottom -------------------------

drop function drop_type
(
	varchar(100) --: typename
);


