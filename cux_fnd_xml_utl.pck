create or REPLACE PACKAGE cux_fnd_xml_utl is
  /*====================================================
  * PROGRAM NAME:
  *        cux_fnd_xml_utl
  * DESCRIPTION:
  *        XML标签输出的通用工具包
  * HISTORY:
  *
  *=====================================================*/
  c_tag_deg number := 0;
  type vararray is table of varchar2(200) index by binary_integer;
  tagstack vararray;
  /*====================================================
  * FUNCTION
  * NAME:
  *       get_string_xml
  * DESCRIPTION:
  *        报表输出中不可识别的XML字符转换成可识别的xml字符
  * ARGUMENT:
  * p_string
  * RETURN:
  * 转换后的字符串
  * HISTORY:
  *
  *=====================================================*/
  function get_string_xml(p_string in varchar2) return varchar2;
  function get_file_start(p_encode varchar2 default null) return varchar2;
  function get_file_end return varchar2;
  function get_tag_start(p_tag_name varchar2
                        ,p_tag_attr varchar2 default null) return varchar2;
  function get_tag_end return varchar2;
  function get_tag(p_tag_name varchar2, p_value varchar2) return varchar2;
end cux_fnd_xml_utl;
/
create or replace package body cux_fnd_xml_utl is
  function get_string_xml(p_string in varchar2) return varchar2 is
    l_temp varchar2(30000);
  begin
    l_temp := '<![CDATA[' || p_string || ']]>';
    return l_temp;
  end get_string_xml;
  function get_file_start(p_encode varchar2 default null) return varchar2 is
    tagnull  vararray;
    l_encode varchar2(100);
  begin
    c_tag_deg := 0;
    tagstack  := tagnull;
    l_encode  := nvl(p_encode,
                     fnd_profile.value('ICX_CLIENT_IANA_ENCODING'));
    return '<?xml version="1.0" encoding="' || l_encode || '"?>';
  end get_file_start;
  function get_tag_start(p_tag_name varchar2
                        ,p_tag_attr varchar2 default null) return varchar2 is
    l_ret varchar2(2000);
  begin
    if p_tag_attr is null then
      l_ret := l_ret || '<' || p_tag_name || '>';
    else
      l_ret := l_ret || '<' || p_tag_name || ' ' || p_tag_attr || '>';
    end if;
    c_tag_deg := c_tag_deg + 1;
    TagStack(c_tag_deg) := p_tag_name;
    return l_ret;
  end get_tag_start;
  function get_tag_end return varchar2 is
    l_ret      varchar2(2000);
    l_tag_name varchar2(200);
  begin
    l_tag_name := tagstack(c_tag_deg);
    c_tag_deg  := c_tag_deg - 1;
    l_ret      := l_ret || '</' || l_tag_name || '>';
    return l_ret;
  end get_tag_end;
  function get_tag(p_tag_name varchar2, p_value varchar2) return varchar2 is
    l_ret varchar2(2000);
  begin
    if regexp_instr(p_value, '[&,<,>,/,",'']') > 0 then
      l_ret := l_ret || '<' || p_tag_name || '>'
               get_string_xml(p_value) || '</' || p_tag_name || '>';
    else
      l_ret := l_ret || '<' || p_tag_name || '>' || p_value || '</' ||
               p_tag_name || '>';
    end if;
  end get_tag;
  function get_file_end return varchar2 is
    l_ret varchar2(2000);
  begin
    for i in 1 .. c_tag_deg loop
      begin
        if l_ret is null then
          l_ret := get_tag_end;
        else
          l_ret := l_ret || chr(10) || get_tag_end;
        end if;
      when
      no_data_found then null;
    end;
  end loop;
  return l_ret;
end get_file_end;
end cux_fnd_xml_utl;
/
