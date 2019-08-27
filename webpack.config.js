const path = require('path')
const fs = require('fs')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const rules = widgetWebpack.getDefaultRules()
const entries = widgetWebpack.getDefaultEntries()
const copy = widgetWebpack.getDefaultCopyList()

const customCopy = copy.concat([
	{
		from: path.join(__dirname, 'node_modules', 'angular-sortable-view', 'src', 'angular-sortable-view.min.js'),
		to: path.join(outputPath, 'vendor'),
	},
	{
		from: path.join(__dirname,'src','_exports','playdata_exporters.php'),
		to: path.join(outputPath,'_exports/','playdata_exporters.php')
	},
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
])

entries['scorescreen.js'] = [
	srcPath+'scorescreen.coffee'
]

entries['scorescreen.css'] = [
	srcPath+'scorescreen.html',
	srcPath+'scorescreen.scss'
]

entries['guides/creator.temp.html'] = [
	srcPath+'_guides/creator.md'
]

entries['guides/player.temp.html'] = [
	srcPath+'_guides/player.md'
]

// this is needed to prevent html-loader from causing issues with
// style tags in the player using angular
let customHTMLAndReplaceRule = {
	test: /\.html$/i,
	exclude: /node_modules/,
	use: [
		{
			loader: 'file-loader',
			options: { name: '[name].html' }
		},
		{
			loader: 'extract-loader'
		},
		{
			loader: 'string-replace-loader',
			options: { multiple: widgetWebpack.materiaJSReplacements }
		},
		{
			loader: 'html-loader',
			options: {
				minifyCSS: false
			}
		}
	]
}

let customRules = [
	rules.loaderDoNothingToJs,
	rules.loaderCompileCoffee,
	rules.copyImages,
	customHTMLAndReplaceRule, // <--- replaces "rules.loadHTMLAndReplaceMateriaScripts"
	rules.loadAndPrefixCSS,
	rules.loadAndPrefixSASS,
	rules.loadAndCompileMarkdown
]


// options for the build
let options = {
	entries: entries,
	copyList: customCopy,
	moduleRules: customRules
}

module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
