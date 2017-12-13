-- •	Склады дилерского центра (названия файла: location)
select
   [Идентификатор склада дилера] = 4
  ,[Название склада дилера] = 'Мэйджор Авто Центр'
  ,[Город] = 'Михалково'
  ,[Адрес] = 'вблизи д. Михалково, п/о Архангельское, а/д «Балтия» 25 км, ТСК'
  ,[Телефон] = '84952292080'

-- •	Цены на запчасти для конечных покупателей (названия файла: user-price)
declare 
   @ReportDate varchar(32)
  ,@SuplNo varchar(32)
  ,@StrPattern varchar(32)

set @ReportDate = '20161015'
set @SuplNo = '3060'
set @StrPattern = '%[' + char(13) + char(9) + char(10) + ';]%'

select 
     [Идентификатор склада дилера] = 4
    ,[Артикул ЗЧ] = MJAM.dbo.pattern_replace(i.ITEMNO, @StrPattern, ' ')
    ,[Стоимость для конечного покупателя в рублях] = i.SELPR * c.Rate
    ,[Дата начала действия цены] = @ReportDate
  from dbo.ITEM i
    outer apply (
      select top 1 Rate = c.C4
        from dbo.CORWS11 c
          outer apply (
            select
              Date = convert(datetime, c.C7, 102)
          ) x
        where c.codaid = 'valuutat'
          and c.C2 = 'RUB'
          and x.Date < @ReportDate
        order by x.Date desc
    ) c
  where i.suplno = @SuplNo
    and exists (
      select 1
        from dbo.OSFI o
        where o.ITEMNO = i.ITEMNO
          and o.SUPLNO = i.SUPLNO
          and o.STOCKFIG > 0
    )

-- •	Поставщики товаров для дилера (названия файла: vendor)
declare 
   @ReportDate datetime
  ,@SuplNo varchar(32)
  ,@StrPattern varchar(32)

set @ReportDate = '20161015'
set @SuplNo = '3060'
set @StrPattern = '%[' + char(13) + char(9) + char(10) + ';]%'

select 
     [Поставщик Код] = s.SUPLNO
    ,[Поставщик Имя] = MJAM.dbo.pattern_replace(s.NAME, @StrPattern, ' ')
  from dbo.SUPL s
  where exists (
      select 1
        from dbo.ORDES16 h
          join dbo.ORRWS16 as o
            on o.DELD >= dateadd(dd, -7, @ReportDate)
            and o.DELD < @ReportDate
            and o.suplno = @SuplNo
            and o.ORDENO = h.ORDENO
        where h.SUPLNO = s.SUPLNO
    )
    and s.SUPLNO not in ('403')
 
-- •	Остатки товаров на сладах дилера (названия файла: remained-item)
declare
   @SuplNo varchar(32)
  ,@StrPattern varchar(32)

set @SuplNo = '3060'
set @StrPattern = '%[' + char(13) + char(9) + char(10) + ';]%'

select
     [Идентификатор склада дилера] = 4
    ,[Поставщик код] = p.SUPLNO
    ,[Артикул ЗЧ] = MJAM.dbo.pattern_replace(s.ITEMNO, @StrPattern, ' ')
    ,[Кол-во] = s.OnStock
    ,[Дата поступления] = convert(varchar(32), p.DELD, 112)
  from (
    select 
         s.ITEMNO
        ,s.SUPlNO
        ,OnStock = sum(isnull(s.STOCKFIG, 0))
      from dbo.OSFI s
      where s.OPERUNIT not in ('S21', 'S22', 'S30')
        and s.suplno = @SuplNo
		and s.STOCKFIG > 0
      group by 
         s.ITEMNO
        ,s.SUPlNO
  ) s
    outer apply (
      select top 1 h.SUPLNO, r.DELD
        from dbo.ALL_ORRW r
          join dbo.ALL_ORDE h
            on h._UNITID = r._UNITID
            and h.ORDENO = r.ORDENO
        where r.ITEMNO = s.ITEMNO
          and r.SUPLNO = s.SUPLNO
          and h.SUPLNO not in ('403')
        order by r.DELD desc
    ) p

-- •	Журнал товарных операций дилера (названия файла: item-ledger)
declare 
   @ReportDate datetime
  ,@SuplNo varchar(32)
  ,@StrPattern varchar(32)

set @ReportDate = '20161015'
set @SuplNo = '3060'
set @StrPattern = '%[' + char(13) + char(9) + char(10) + ';]%'

select 
     [Тип операции] = t.OperType
    ,[Идентификатор склада дилера] = 4
    ,[Дата] = convert(varchar(32), t.Date, 112)
    ,[Артикул ЗЧ] = MJAM.dbo.pattern_replace(t.ITEMNO, @StrPattern, ' ')
    ,[Стоимость ед. в рублях] = t.UnitPrice
    ,[Кол-во] = t.NUM
    ,[Стоимость итого] = t.RSUM
    ,[Поставщик Код] = t.SuplCode
    ,[Заказ-наряд № / Инвойс] = MJAM.dbo.pattern_replace(t.RecNo, @StrPattern, ' ')
  from (
    select 
         OperType = 'Продажа'
        ,RecNo
        ,ITEMNO
        ,Date
        ,UnitPrice = cast(AFFTOSV * CURRRATE2 / NUM as numeric(16, 2))
        ,NUM
        ,RSUM
        ,SuplCode = null
      from (
        select
             f.RecNo
            ,r.ITEMNO
            ,Date = max(b.BILLD)
            ,b.CURRRATE2
            ,AFFTOSV = sum(isnull(r.AFFTOSV, 0))
            ,NUM = sum(isnull(r.NUM, 0))
            ,RSUM = sum(isnull(r.RSUM, 0))
          from dbo.ALL_GROW r
            join dbo.ALL_GBIL b
              on b._UNITID = r._UNITID
              and b.GSALID = r.GSALID
              and b.GRECNO = r.GRECNO
            outer apply (
              select
                 RecNo = b._UNITID + '-' + cast(b.GRECNO as varchar(32)) + 'K'
            ) f
          where r.SUPLNO = @SuplNo
            and r._UNITID not in ('S21', 'S22', 'S30')
            and b.BILLD >= dateadd(dd, -7, @ReportDate)
            and b.BILLD < @ReportDate
            and b.BTYPE != '41'
          group by 
             f.RecNo
            ,r.ITEMNO
            ,b.CURRRATE2
      ) t
    union all 
    select 
         OperType = 'Продажа'
        ,RecNo
        ,ITEMNO
        ,Date
        ,UnitPrice = cast(AFFTOSV * CURRRATE2 / NUM as numeric(16, 2))
        ,NUM
        ,RSUM
        ,SuplCode = null
      from (
        select
             f.RecNo
            ,r.ITEMNO
            ,Date = max(b.BILLD)
            ,b.CURRRATE2
            ,AFFTOSV = sum(isnull(r.AFFTOSV, 0))
            ,NUM = sum(isnull(r.NUM, 0))
            ,RSUM = sum(isnull(r.RSUM, 0))
          from ALL_SROW r
            join dbo.ALL_SBIL b
              on b._UNITID = r._UNITID
              and b.SSALID = r.SSALID
              and b.SRECNO = r.SRECNO
            join dbo.ALL_SSAL s
              on s._UNITID = b._UNITID
              and s.SSALID = b.SSALID
            outer apply (
              select
                 RecNo = b._UNITID + '-' + cast(b.SRECNO as varchar(32)) + 'V' 
            ) f
          where r.SUPLNO = @SuplNo
            and r._UNITID not in ('S21', 'S22', 'S30')
            and b.BILLD >= dateadd(dd, -7, @ReportDate)
            and b.BILLD < @ReportDate
            and b.BTYPE != '41'
            and s.STYPE != 'Z'
          group by 
             f.RecNo
            ,r.ITEMNO
            ,b.CURRRATE2
      ) t
    union all
    select
         OperType = 'Покупка'
        ,f.RecNo
        ,r.ITEMNO
        ,Date = max(r.DELD)
        ,UnitPrice = avg(r.BUYPR * c.Rate)
        ,NUM = sum(isnull(case when h.TYPEID = 'O' then r.DNUM else r.ONUM end, 0))
        ,RSUM = avg(r.BUYPR * c.Rate) * sum(isnull(case when h.TYPEID = 'O' then r.DNUM else r.ONUM end, 0))
        ,SuplCode = h.SUPLNO
      from dbo.ALL_ORRW r
        join dbo.ALL_ORDE h
          on h._UNITID = r._UNITID
          and h.ORDENO = r.ORDENO
        outer apply (
          select
              RecNo = r._UNITID + '-' + cast(r.PRECNO as varchar(32))
        ) f
        outer apply (
          select top 1 Rate = c.C4
            from dbo.CORWS11 c
              outer apply (
                select
                  Date = convert(datetime, c.C7, 102)
              ) x
            where c.codaid = 'valuutat'
              and c.C2 = 'RUB' 
              and x.Date < @ReportDate
            order by x.Date desc
        ) c
      where r.SUPLNO = @SuplNo
        and r._UNITID not in ('S21', 'S22', 'S30')
        and r.DELD >= dateadd(dd, -7, @ReportDate)
        and r.DELD < @ReportDate
        and h.SUPLNO not in ('403')
      group by 
         f.RecNo
        ,r.ITEMNO
        ,h.SUPLNO
  ) t

-- •	Упущенные продажи дилера (названия файла: lost-sales)
declare 
   @ReportDate varchar(32)
  ,@SuplNo varchar(32)
  ,@StrPattern varchar(32)

set @ReportDate = '20161015'
set @SuplNo = '3060'
set @StrPattern = '%[' + char(13) + char(9) + char(10) + ';]%'

select 
    [Артикул] = MJAM.dbo.pattern_replace(i.ITEMNO, @StrPattern, ' ')
   ,[Дата] = @ReportDate
   ,[Кол-во] = max(i.GLOBAMOUNT)
  from dbo.ALL_ITDT as i
  where i.SUPLNO = @SuplNo
    and i._UNITID not in ( 'S21', 'S22', 'S30')
    and i.SAVDT >= dateadd(dd, -7, @ReportDate)
    and i.SAVDT < @ReportDate
    and i.DEMANDCODE <> '01'
  group by 
     i.ITEMNO
