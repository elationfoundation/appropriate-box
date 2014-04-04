module("luci.controller.appropriate.box", package.seeall)

local ddebug = require "luci.commotion.debugger"

local path = {'/www', 'luci', 'media', 'app_box' }

function index()
   entry({'commotion', 'appropriate'}, call("prepare_box"), "Commotion Media Server", 10).dependent = false
end

function prepare_box()
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   local util = require "luci.commotion.util"

   local filepath = table.concat( path, '/' )
   ddebug.log("FIELPATH")
   ddebug.log(filepath)
  --in case it is not working check this variable
   local file_permission = nixio.fs.access(filepath)
   if not file_permission then
	  ddebug.log("The appropriate box is broken because you don't have permission.")
   end
 
   -- causes media files to be uploaded to their namesake on the server.
   util.upload(filepath.."/", "upload")

   if luci.http.formvalue("file") then
	  download()
   end
   
   luci.template.render("appropriate/box", {path=path, filepath=filepath})
end

function download()
  filename = luci.http.formvalue("file")

  -- no file name provided
  if not filename then
    luci.http.status(403, "Forbidden")
    return
  end

  -- no relative paths with backrefs
  if filename:find("%.%.") then
    luci.http.status(403, "Access denied")
    return
  end

  -- no absolute paths
  if # filename > 0 and filename:sub(1,1) == '/' then
    luci.http.status(403, "Access denied")
    return
  end

  local folder = table.concat( path, '/' )
  local f = io.open(folder .. filename)

  -- file does not exist

  if not f then
    luci.http.status(403, "Access denied")
    return
  end

  -- send it

  luci.http.prepare_content("application/force-download")
  luci.http.header("Content-Disposition", "attachment; filename=" .. filename)
  luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)

  io.close(f)
end
