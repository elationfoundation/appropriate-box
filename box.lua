module("luci.controller.pirate.box", package.seeall)

function index()
   entry({"media", "viewer"}, call("prepare_box"), "Commotion Media Server", 10).dependent = false
   entry({"media", "download"}, call("download"), "Commotion Media Server Download").dependent = false
end

function prepare_box()
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   
   local file_permission = nixio.fs.access("/www/luci/media/pirate")
   local pirate_folder = "/www/luci/media/pirate/"
   
   -- causes media files to be uploaded to their namesake on the server.
   local fp
   luci.http.setfilehandler(
	  function(meta, chunk, eof)
		 if not fp then
			if meta and meta.name == "file" then
			   fp = io.open(pirate_folder .. meta.file, "w")
			end
		 end
		 if chunk then
			fp:write(chunk)
		 end
		 if eof then
			fp:close()
		 end
		 end
						   )   
   --
   -- Load luci-template
   --
   luci.template.render("pirate-box/mediasvr")
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

  local pirate_folder = "/www/luci/media/pirate/"
  local f = io.open(pirate_folder .. filename)

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
