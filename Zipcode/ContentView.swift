//
//  ContentView.swift
//  Zipcode
//
//  Created by 卜部大輝 on 2025/02/15.
//

import SwiftUI
import Alamofire

// JSONをフラットマップにするためのStruct
struct ZipCloudResponse: Codable {
    let message: String?
    let results : [Address]?
    let status : Int
}

// ForEachで繰り返し処理するためにHashableにも準拠
struct Address: Codable, Hashable {
    let address1: String
    let address2: String
    let address3: String
    let kana1: String
    let kana2: String
    let kana3: String
    let prefcode: String
    let zipcode: String
    
    // 漢字部分をくっつける処理
    func address() -> String {
        return address1 + address2 + address3
    }
    
    // カタカナ部分をくっつける処理
    func kana() -> String {
        return kana1 + kana2 + kana3
    }
}


struct ContentView: View {
    let baseUrlStr = "https://zipcloud.ibsnet.co.jp/api/search"
 // リクエストのURLの共通部分
    
    @State var results: [Address] = [] // 検索結果を入れる配列
    @State private var searchText = "" // テキストフィールドに入力した値を入れる変数
    @State private var isPresented = false // アラートの表示・非表示を管理
    @State private var isEmpty = false // 検索結果の住所の有無を管理
    @FocusState private var isFocused: Bool  // キーボードのフォーカスを管理(閉じるため)
    
    var body: some View {
        VStack {
            // 検索したい郵便番号を入力するフィールド
            TextField("検索したい郵便番号を入力", text: $searchText)
                .padding(8)
                .border(.gray, width: 3)
                .padding()
                .keyboardType(.numberPad)
                .focused($isFocused) // フォーカス管理の変数を登録

                // キーボードの上部に検索ボタン設置
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        // 検索ボタン
                        Button {
                            requestAddressFromZipcode(zipcode: searchText)
                            isFocused = false // リクエスト送信したらキーボード閉じる
                        } label: {
                            Text("\(Image(systemName: "magnifyingglass")) 検索")
                        }
                        
                        // アラート
                        .alert("Error !", isPresented: $isPresented) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("数字を7文字入力してください。")
                        }
                    }
                }
            // 検索結果を表示するリスト
            List {
                ForEach(results, id: \.self) { result in
                    Text(result.address() + "\n" + result.kana())
                }
            }
        }
        .padding()
        // TextField以外をタップしてもフォーカスが外れる(キーボードが閉じる)ようにする
        .onTapGesture {
            isFocused = false
        }
    }
    
    // リクエスト送信用のメソッド
    func requestAddressFromZipcode(zipcode: String) {
        // 正規表現で数字7文字かチェックする
        if !isZipcode(enteredText: zipcode) {
            // チェックに引っかかったらアラートを表示
            isPresented = true
            return
        }

        //リクエストに含ませるパラメータを用意(中身は検索する郵便番号)
        let parameters: [String: Any] = ["zipcode": zipcode]
        //Alamofireを使ってリクエストを送信
        AF.request(
            baseUrlStr,    //リクエストを送るためのURLの共通部分
            method: .get,  //HTTPメソッドを指定(GETの場合は省略可能)
            parameters: parameters  //リクエストに含ませるパラメータ
        ).responseDecodable(of: ZipCloudResponse.self) { response in
            //返ってきたレスポンス(response)を場合分けして処理
            switch response.result {
                // 通信成功
            case .success(let value):
                //レスポンスに住所が無いときはreturnで処理を抜ける
                guard let results = value.results else {
                    print("No Address")
                    return
                }
                self.results = results
            
            // 通信失敗時
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // 正規業源で数字7文字かチェックする関数
    func isZipcode(enteredText: String) -> Bool {
        let pattern = "^[0-9]{7}$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false } // NSRegularExpressionをインスタンス化
        let matches = regex.matches(in: enteredText, range: NSRange(location: 0, length: enteredText.count)) // パターンマッチを確認
        return matches.count == 1 ? true : false  // 結果によって真偽値を返す
    }
}

#Preview {
    ContentView()
}
