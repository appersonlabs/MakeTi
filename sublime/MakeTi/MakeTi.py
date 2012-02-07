import sublime, sublime_plugin

class MakeTiCommand(sublime_plugin.WindowCommand):
    instance_list = ["clean","ipad","iphone", "android", "web"]
	
    def run(self, *args, **kwargs):
		# p = self.window.active_view().file_name()
        print args, kwargs
        self.window.show_quick_panel(self.instance_list , self._quick_panel_callback)

    def _quick_panel_callback(self, index):

	root = self.window.folders()[0];
	# sublime.error_message(root)
		
        if (index > -1):
			if (self.instance_list[index] == 'clean'):
				self.window.run_command("exec",{"cmd":["make","-C",root,"clean"]})
			else:	
				s = sublime.load_settings("MakeTi.sublime-settings")		
				self.window.run_command("exec",{"cmd":["make","-C",root,"run","platform="+self.instance_list[index],"android_sdk_path="+s.get('androidsdk')]})