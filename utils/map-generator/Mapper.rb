require 'rubygems'
require 'gosu'
require 'texplay'
include Gosu

class Game < Window
	attr_reader :map, :camera_x, :camera_y

	def initialize
		if(not ARGV.length==4)
			puts "INCORRECT ARGUMENTS. Should be: <image filename> <width> <height> <preview (yes/no)>"
			exit
		end
	
		super(640, 480, false)
		
		# make things retro
		begin; Gosu::enable_undocumented_retrofication; rescue; end
		self.caption = "Tiny Miasmata Mapper"
		@camera_x = @camera_y = 0
		
		# set up game
		@map = Map.new(self, ARGV[0], ARGV[1].to_i, ARGV[2].to_i)
		@map.build
		
		exit if ARGV[3]=="no"
	end
  
	def update
		@camera_x = mouse_x
		@camera_y = mouse_y
	end
  
	def draw
		self.scale(2,2) do
			@map.draw(@camera_x, @camera_y)
		end
	end
  
	def button_down(id)
		if id == KbEscape then close end
	end
end

class Tile
	attr_reader :image, :type
	
	SIZE = 8
	
	def initialize(type, image)
		@type = type
		@image = image
	end
end

class Section
	attr_reader :header, :data
	
	def initialize(header, data)
		@header = header
		@data = data
	end
end

class Group
	attr_reader :types
	
	def initialize
		@types = Array.new(16)
		
		for i in 0...@types.length
			@types[i] = false
		end
	end
	
	def addType(index)
		@types[index] = true
	end

	# find out if this group already contains this type
	def contains(index)
		return @types[index]
	end
	
	def getIndex(type)
		count = 0
		for i in 0...type
			count += 1 if types[i]
		end
		
		if(count>=4)
			puts "BUILD ERROR: too many types in one section!"
			exit
		end
		
		return count
	end
end

class Map
	attr_reader :width, :height
  
	def initialize(window, filename, width, height)
		@window = window
		
		# size in screenfuls
		@height = width
		@width = height
		
		# info to build map data
		@group_table = Array.new
		@sections = Array.new(@height*@width)
		
		img_empty, img_admin, img_rock, img_dirt, img_wood, img_sand, img_torch = *Image.load_tiles(window, "tileset.png", 8, 8, true)
		
		@draw_width = @window.width/Tile::SIZE
		@draw_height = @window.height/Tile::SIZE
		
		map_src = Image.new(@window, filename)
		@tiles = Array.new(@width)
		
		c_admin	= [0,		0,		0,		255]
		
		c_rock	= [119,		119,	119,	255]
		c_dirt	= [256,		0,		256,	255]
		c_wood	= [0,		256,	0,		255]
		
		c_sand	= [256,		256,	0,		255]
		c_torch	= [256,		0,		0,		255]
		
		for x in 0...@width*10
			@tiles[x] = Array.new(@height)
			
			for y in 0...@height*6
				colors = map_src.get_pixel(x, y)
				for i in 0...colors.length
					colors[i] = (colors[i]*256).floor
				end
				
				# if(colors[0]!=256 or colors[1]!=256 or colors[2]!=256)
					# puts colors[0].to_s+", "+colors[1].to_s+", "+colors[2].to_s+", "+colors[3].to_s
				# end
				
				case colors
					when c_admin
						@tiles[x][y] = Tile.new(:admin, img_admin)
					when c_rock
						@tiles[x][y] = Tile.new(:rock, img_rock)
					when c_dirt
						@tiles[x][y] = Tile.new(:dirt, img_dirt)
					when c_wood
						@tiles[x][y] = Tile.new(:wood, img_wood)
					when c_sand
						@tiles[x][y] = Tile.new(:sand, img_sand)
					when c_torch
						@tiles[x][y] = Tile.new(:torch, img_torch)
					else
						@tiles[x][y] = Tile.new(:empty, img_empty)
				end
			end
		end
	end
	
	def build
		for section_y in 0...@height
			for section_x in 0...@width
				current_g = Group.new
				data = Array.new
			
				for y in 0...6
					for x in 0...10
						type = getType(@tiles[10*section_x+x][6*section_y+y].type)
						
						if(type)
							current_g.addType(type)
						else
							puts "BUILD ERROR: unrecognized type"
							exit
						end
					end
				end
				
				puts "section #"+(@width*section_y+section_x).to_s
				for y in 0...6
					for x in 0...10
						type = getType(@tiles[10*section_x+x][6*section_y+y].type)
						
						data[y*10+x] = current_g.getIndex(type)
						print current_g.getIndex(type).to_s+" "
					end
					puts
				end
				puts
				
				# check if group already exists and set header
				header = nil
				for i in 0...@group_table.length
					if(@group_table[i].types==current_g.types)
						header = i
						break
					end
				end
				
				if(header==nil)
					header = @group_table.length
					@group_table<<current_g
				end
				
				@sections[section_y*@width+section_x] = Section.new(header, data)
			end
		end
		
		# CREATE CODE
		code = ""
		
		code += ".equ\tMAP_WIDTH = "+@width.to_s+"\n"
		code += ".equ\tMAP_HEIGHT = "+@height.to_s+"\n\n"
		
		# print group table
		code += "GROUP_TABLE:\n"
		for i in 0...@group_table.length
			bits = @group_table[i].types
			value = 0
			for bit in 0...bits.length
				if(bits[bit])
					value += 2**bit
				end
			end

			# pad and print
			code += "\t.dw $"+paddedHex(value, 4)+"\n"
		end
		code += "\n"
		
		# print section data
		code += "SECTION_DATA:\n"
		for i in 0...@sections.length
			current_s = @sections[i]
		
			code += "\tsection_"+i.to_s+":\n"
			
			code += "\t\t;header->data\n"
			code += "\t\t.db $"+paddedHex(@sections[i].header, 2)+", "
			
			datastring = ""
			for chunk in 0...15
				byte = 0
				for part in 0...4
					tile = current_s.data[chunk*4+part]
					byte |= tile*(2**(part*2))
				end
				
				datastring += "$"+paddedHex(byte, 2)
				datastring += ", " if not chunk==14
			end
			code += datastring+"\n"
			code += "\n"
		end
		
		output_file = File.new("map.dat", "w")
		output_file.write(code)
		output_file.close
		
		puts "BUILD COMPLETED"
	end
	
	def paddedHex(num, length)
		hex = num.to_s(16)
		
		text = ""
		for digit in 0...(length-hex.length)
			text += "0"
		end
		return text+hex
	end
	
	def getType(type)
		case type
			when :empty
				return 0
			when :admin
				return 1
			when :rock
				return 2
			when :dirt
				return 3
			when :wood
				return 4
			when :sand
				return 5
			when :torch
				return 6
			else
				return nil
		end
	end
  
	def draw(cam_x, cam_y)
		# draw tiles
		for y in 0...@draw_height
			for x in 0...@draw_width
				tile = tile(cam_x+x*Tile::SIZE, cam_y+y*Tile::SIZE)
				if tile
					tile.image.draw(x*Tile::SIZE-cam_x%Tile::SIZE, y*Tile::SIZE-cam_y%Tile::SIZE, 0)
				end
			end
		end
	end
	
	# Solid at a given pixel position?
	def solid?(x, y)
		if(x>=0 and y>=0 and x<@width*Tile::SIZE and y<@height*Tile::SIZE)
			return @tiles[x/Tile::SIZE][y/Tile::SIZE]
		else
			return nil
		end
	end
	
	def tile(x, y)
		index_x = x/Tile::SIZE
		index_y = y/Tile::SIZE
		
		if(index_x>=0 and index_x<@tiles.length and index_y>=0 and index_y<@tiles.length)
			return @tiles[index_x][index_y]
		else
			return nil
		end
	end
end

Game.new.show
