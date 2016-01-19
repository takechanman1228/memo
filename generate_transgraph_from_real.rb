require 'csv'
require 'pp'
require 'logger'
require 'set'
require 'unf'

def main
  measure_feature_value_precision

end
class Array
  # 要素の平均を算出する
  def avg
    inject(0.0){|r,i| r+=i }/size
  end
  # 要素の分散を算出する
  def variance
    a = avg
    inject(0.0){|r,i| r+=(i-a)**2 }/size
  end
  # 標準偏差を算出する
  def standard_deviation
    Math.sqrt(variance)
  end
end
def levenshtein_distance(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
        d[i-1][j-1]       # no operation required
      else
        [ d[i-1][j]+1,    # deletion
        d[i][j-1]+1,    # insertion
        d[i-1][j-1]+1,  # substitution
      ].min
    end
  end
end
d[m][n]
end
class Transgraph
  def initialize(input_filename)
    @pivot = {}
    @lang_a_b = {}
    @lang_b_a = {}
    @lang_a_p = {}
    @lang_b_p = {}
    @lang_p_a = {}
    @lang_p_b = {}
    @node_a = Set.new
    @node_b = Set.new
    CSV.foreach(input_filename) do |row|
      if row.size==3
        array_of_a = split_comma_to_array(row[1])
        # if row[2]
        array_of_b  = split_comma_to_array(row[2])
        # pp array_of_b
        @pivot[row[0]]=[array_of_a,array_of_b] #{"pivot"=>[[a1,a2,a3,..], [b1,b2,b3,..]]}

        @lang_p_a[row[0]] = array_of_a
        @lang_p_b[row[0]] = array_of_b
        array_of_a.each{|a|
          array_of_b.each{|b|
            @lang_a_b[a]=array_of_b #{"a1"=>[b1,b2,b3,..]}とか{"a2"=>[b1,b2,b3,..]}
            @lang_b_a[b]=array_of_a #{"b1"=>"a1,a2,a3,..]"}
            #aやbからみたとき、複数のpivotが対応することがある
            if @lang_a_p.has_key?(a)
              @lang_a_p[a] << row[0] #{"a1"=>Set[pivot1,pivot2,..]}
              # pp @lang_a_p[a]
            else
              @lang_a_p[a]=Set[row[0]] #{"a1"=>Set[pivot]}
            end
            if @lang_b_p.has_key?(b)
              @lang_b_p[b] << row[0] #{"b1"=>Set[pivot1,pivot2,..]}
              # pp @lang_b_p[b]
            else
              @lang_b_p[b]=Set[row[0]] #{"b1"=>"Set[pivot]}
              # pp @lang_b_p[b][0]

            end
          }
        }
        array_of_a.each{|a|
          @node_a<<a.to_s
        }
        array_of_b.each{|b|
          @node_b<<b.to_s
        }
      end
    end
  end
  attr_accessor :pivot
  attr_accessor :lang_a_b
  attr_accessor :lang_b_a
  attr_accessor :lang_a_p
  attr_accessor :lang_b_p
  attr_accessor :lang_p_a
  attr_accessor :lang_p_b
  attr_accessor :node_a
  attr_accessor :node_b
end

class Answer
  def initialize(answer_filename)
    @answer = {}
    @answer_head_trans = Hash.new {|h,k| h[k]=[]}
    CSV.foreach(answer_filename) do |row|
      if row.size>=2
        @answer[row[0]]=row[1..-1]
        if row[0 .. -1].size>1
          row[1..-1].each{|trans|
            if answer_head_trans.has_key?(trans)
              answer_head_trans[trans] << row[0]
              #まだ登録されていないkeyならvalueに追加
            else
              answer_head_trans[trans] << row[0]
            end
          }
        end
      end
    end
  end
  attr_accessor :answer
  attr_accessor :answer_head_trans
end
class Result
  def initialize(result_filename)
    @result = {}
    @result_head_trans = Hash.new {|h,k| h[k]=[]}
    @is_true=Hash.new { |h,k| h[k] = {} } #二重ハッシュ
    CSV.foreach(result_filename) do |row|
      if row.size>=2
        @result[row[0]]=row[1]
        @result_head_trans[row[1]]=row[0]
        @is_true[row[0]][row[1]]=[row[2]]
      end
    end
  end
  attr_accessor :result
  attr_accessor :result_head_trans
  attr_accessor :is_true

end


def split_comma_to_array (text)
  # text=text.gsub(/"/, '')
  lang_arr=text.split(",")
  return lang_arr
end

def measure_feature_value_precision
  languages = ["JaToEn_EnToDe","JaToDe_DeToEn","JaToEn_JaToDe","Ind_Mnk_Zsm2","Zh_Uy_Kz"]
  # languages = ["JaToEn_EnToDe0105"]
  # languages = ["Ind_Mnk_Zsm2","Zh_Uy_Kz"]

  # 1.upto(10) do |pivot_connected_fixed|
  languages.each{|language|

    is_population_connected_only=1 #母集団の取り方
    # pivot_connected_fixed=2 #ピボット共有率を計測する際の分母(繋がっているノード数)を指定
    output_folder="generated_trans_from_real/"
    min=1
    if language=="Ind_Mnk_Zsm"
      answer_filename="answer/Mnk_Zsm.csv"
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      max=155 #Indのときだけ0からはじめる
      min=0
    elsif language=="Ind_Mnk_Zsm2" #品詞なしの場合
      input_filename="partition_graph_1227/Ind_Mnk_Zsm_hinsinashi0104/Ind_Mnk_Zsm_subgraph_"
      answer_filename="answer/Mnk_Zsm.csv"
      one_to_one_filename="Ind_Mnk_Zsm"
      max=252
    elsif language=="JaToEn_JaToDe"
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      answer_filename="answer/En_De.csv"
      one_to_one_filename="JaToEn_JaToDe"
      max=389
    elsif language=="JaToEn_EnToDe"
      max=453
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      answer_filename="answer/Ja_De.csv"
      one_to_one_filename="JaToEn_EnToDe"
    elsif language=="JaToDe_DeToEn"
      max=364
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      answer_filename="answer/Ja_En.csv"
      one_to_one_filename="JaToDe_DeToEn"

    elsif language=="Zh_Uy_Kz"
      max=1475
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      # answer_filename="answer/Uy_Kz_answer_has_many.csv"
      # answer_filename="answer/Uy_Kz.csv"
      answer_filename="answer/Marhaba_and_1distance.csv"
      one_to_one_filename="Zh_Uy_Kz"
    elsif language=="JaToEn_EnToDe0105"
      max=207
      input_filename="partition_graph_1227/"+language+"/"+language+"_subgraph_"
      answer_filename="answer/Ja_De.csv"
    end
    answer = Answer.new(answer_filename)
    one_to_one = Result.new("1-1/csv/"+one_to_one_filename+".csv")

    all_trans_sr_standardized=Array.new
    # io.puts "トランスグラフid,適合率,リーチャブル,ピボット共有率,ピボット共有率について,適合率について"
    min.upto(max) do |transgraph_itr|
      File.open("#{output_folder}#{language}/"+transgraph_itr.to_s+".csv", "w") do |io| #ファイルあるなら末尾追記

        # begin
        # pp "****************#{i}******************"
        transgraph = Transgraph.new(input_filename+"#{transgraph_itr}.csv")
        # pp transgraph.nofde_a
        pivot_connected=Set.new
        pivot_share=Set.new
        raw_output={}
        each_trans_sr_standardized=Array.new

        pivot_connected_num=Array.new #答えのA-Bペアのどちらかと繋がっているpivotの数
        pivot_share_num=Array.new #答えのA-Bペアの両方と繋がっているpivotの数
        share_ratio=Array.new #pivotの共有率
        precision_arr=Array.new
        string_precision=""

        #適合率計算用
        is_true=0
        is_false=0
        is_not_included=0
        # 母集団データのピボット共有率の計測
        transgraph.node_a.each{|node_a|
          transgraph.node_b.each{|node_b|
            pivot_connected=transgraph.lang_a_p[node_a] + transgraph.lang_b_p[node_b]#setの和部分
            pivot_share=transgraph.lang_a_p[node_a] & transgraph.lang_b_p[node_b]#setの共通部分
            if is_population_connected_only==1 && pivot_connected.size==0 #繋がっていないものがある場合は母集団としカウントしない
              # print("とばす")
            else
              # if pivot_connected.size > 1 #母集団のピボット共有率の分母が1の場合はランダム要素が多いので弾く
              # if pivot_connected.size == pivot_connected_fixed
              # if answer.answer.has_key?(node_a) && answer.answer[node_a].include?(node_b)
              #   pp "母集団から除外"
              #   pp answer.answer[node_a]
              #   pp node_a
              #   pp node_b
              # else
              pivot_connected_num.push(pivot_connected.size)#answer_valueとanswer_keyと接続しているpivot
              pivot_share_num.push(pivot_share.size)
              share_ratio.push(pivot_share_num[-1].fdiv(pivot_connected_num[-1])) #pivotの共有率
              # end
              # end
            end
            # }
          }
        }

        #このトランスグラフの適合率を計測するのにaだけ走査
        transgraph.node_a.each{|node_a_result|
          if one_to_one.result.has_key?(node_a_result)
            node_b_result=one_to_one.result[node_a_result]
            is_true_false_ab=one_to_one.is_true[node_a_result][node_b_result][0].to_i
            if is_true_false_ab==1 #正解
              precision_arr.push(1)
              string_precision+="True->#{node_a_result}:#{node_b_result},"
            elsif is_true_false_ab==2 #不正解
              precision_arr.push(0)
              string_precision+="False->#{node_a_result}:#{node_b_result}."
            else
              # pp "正解不正解判断できず"
              # pp node_a_result
              # pp node_b_result
              # pp is_true_false_ab
            end
          end
        }


        reachable_node_num_arr=Array.new #pivotの共有率
        # has_answer=0
        # kvstring=""
        reachable_node_num=0
        is_already_reachable={}

        #1つのnode_aがもつについてのリーチャブルなnode_b数
        transgraph.node_a.each{|node_a|
          transgraph.lang_a_p[node_a].each{|reachable_pivot|
            transgraph.lang_p_b[reachable_pivot].each{|reachable_target|
              if is_already_reachable.has_key?(reachable_target) && is_already_reachable[reachable_target]==1
                # pp "reachableすでに登録済み"
              else
                reachable_node_num+=1
                is_already_reachable[reachable_target]=1
              end
            }
          }
          reachable_node_num_arr.push(reachable_node_num)
          reachable_node_num=0
          is_already_reachable={}
        }
        reachable_node_num=0
        is_already_reachable={}

        #1つのnode_bがもつについてのリーチャブルなnode_a数
        transgraph.node_b.each{|node_b|
          transgraph.lang_b_p[node_b].each{|reachable_pivot|
            transgraph.lang_p_a[reachable_pivot].each{|reachable_target|
              if is_already_reachable.has_key?(reachable_target) && is_already_reachable[reachable_target]==1
                # pp "reachableすでに登録済み"
              else
                reachable_node_num+=1
                is_already_reachable[reachable_target]=1
              end
            }
          }
          reachable_node_num_arr.push(reachable_node_num)
          reachable_node_num=0
          is_already_reachable={}
        }


        pivot_connected_num_answer=Array.new #答えのA-Bペアのどちらかと繋がっているpivotの数
        pivot_share_num_answer=Array.new #答えのA-Bペアの両方と繋がっているpivotの数
        share_ratio_answer=Array.new #pivotの共有率
        has_answer=0
        kvstring=""
        reachable_node_num_answer=Array.new #pivotの共有率
        reachable_node_num_answer=0
        is_already_reachable_answer={}

        #答えのピボット共有率
        answer.answer.each{|answer_key, answer_values|
          if answer_values
            answer_values.each{|answer_value|#全てのanswerのA-Bについて走査
              is_already_reachable_answer={}
              if transgraph.lang_a_b.has_key?(answer_key)#同じ日本語の見出し語があるか
                if transgraph.lang_a_b[answer_key].include?(answer_value)#同じドイツ語の単語があるか
                  # pp "#{answer_key} & #{answer_value} exists"
                  kvstring+="#{answer_key} and #{answer_value} exists"
                  pivot_connected=transgraph.lang_a_p[answer_key] + transgraph.lang_b_p[answer_value]#setの和部分
                  pivot_share=transgraph.lang_a_p[answer_key] & transgraph.lang_b_p[answer_value]#setの共通部分

                  # if pivot_connected.size > 1 #答えペアのピボット共有率の分母が1の場合はランダム要素が多いので弾く
                  # if pivot_connected.size ==pivot_connected_fixed
                  #答えがもともと繋がっていない場合は省く
                  if pivot_share.size !=0
                    pivot_connected_num_answer.push(pivot_connected.size)#answer_valueとanswer_keyと接続しているpivot
                    pivot_share_num_answer.push(pivot_share.size)
                    share_ratio_answer.push(pivot_share_num_answer[-1].fdiv(pivot_connected_num_answer[-1])) #pivotの共有率
                    # pp "こたえあり"
                  end
                  # end
                end
              end
            }
          end



        }
        # pp "share_ratio_answer"
        # pp share_ratio_answer
        # pp "share_ratio"
        # pp share_ratio
        # pp "precision_arr"
        # pp precision_arr

        if share_ratio_answer.size > 0 && share_ratio.size > 0 && precision_arr.size>0
          # pp "****************#{transgraph_itr}******************"

          if share_ratio.standard_deviation !=0
            share_ratio_answer.each{|sr_answer|
              each_trans_sr_standardized.push((sr_answer-share_ratio.avg)/share_ratio.standard_deviation)
            }
          else
            # 標準偏差が0ということはすべてのshare_ratioの値が同じとき
            share_ratio_answer.each{|sr_answer|
              each_trans_sr_standardized.push(0)
            }
          end
          # pp "ファイル書き込み"
          # puts transgraph_itr.to_s+","+reachable_node_num_arr.avg.to_s+","+each_trans_sr_standardized.avg.to_s+","+precision_arr.avg.to_s+","+kvstring+","+string_precision
          node_a_number=transgraph.node_a.length
          node_b_number=transgraph.node_b.length
          node_p_number=transgraph.pivot.length

          transgraph.pivot.each_with_index {|node_p, itr_p|
            name_p ="p-#{itr_p}-#{node_a_number}-#{node_p_number}-#{node_b_number}-#{reachable_node_num_arr.avg.to_s}"
            pivot_name= node_p[0]
            io.print("\""+name_p+"\",\"")

            name_a_arr=Array.new
            name_b_arr=Array.new
            node_p[1][0].each_with_index {|node_a_name, itr_a|
              name_a_arr[itr_a]="a-#{itr_a}-#{node_a_number}-#{node_p_number}-#{node_b_number}-#{reachable_node_num_arr.avg.to_s}"
              io.print(name_a_arr[itr_a]+",")
            }
            io.print("\"")
            pp node_p[1][1].each_with_index{|node_b_name, itr_b|
              name_b_arr[itr_b]="b-#{itr_b}-#{node_a_number}-#{node_p_number}-#{node_b_number}-#{reachable_node_num_arr.avg.to_s}"
              io.print(name_b_arr[itr_b]+",")
            }
            io.print("\"\n")
          }
          # File.open(output_folder+"precision/features_#{language}.csv", "a") do |io| #ファイルあるなら末尾追記
          # io.puts transgraph_itr.to_s+","+precision_arr.avg.to_s+","+reachable_node_num_arr.avg.to_s+","+each_trans_sr_standardized.avg.to_s+","+kvstring+","+string_precision
          # end
          pp each_trans_sr_standardized.avg
          all_trans_sr_standardized.push(each_trans_sr_standardized.avg)

        end
      end
    end
  }
end




main