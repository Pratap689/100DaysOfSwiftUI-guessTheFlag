//
//  ContentView.swift
//  GuessTheFlag
//
//  Created by netset on 18/02/22.
//

import SwiftUI

struct ContentView: View {
    @State private var countries = ["Estonia", "France", "Germany", "Ireland", "Italy", "Nigeria", "Poland", "Russia", "Spain", "UK", "US"].shuffled()
    @State private var correctAnswer = Int.random(in: 0...2)
    @State private var showAlert: Bool = false
    @State private var scoreTitle: String = ""
    @State private var animateDuration = 0.0
    @State private var score: Int = 0
    @State private var is3dAnimation = false
    @State private var noOfAttemptsLeft: Int = 5
    var body: some View {
        ZStack {
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)], center: .top, startRadius: 200, endRadius: 650)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    Spacer()
                    Spacer()
                    Text("No of Attempts Left: \(noOfAttemptsLeft)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding([.leading, .top], 30)
                        .frame(minWidth: 300, idealWidth: .infinity, maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50, alignment: .leading)
                    VStack {
                        Spacer()
                        Text("Guess The Flag")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                        VStack(spacing: 15) {
                            VStack {
                                Text("Tap the flag of")
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(.secondary)
                                Text("\(countries[correctAnswer])")
                                    .font(.largeTitle.weight(.semibold))
                            }
                            
                            VStack {
                                FlagView(countryName: countries[0],callBack: {
                                    flaggedTapped(0)
                                }, isAnimating: $is3dAnimation, animateDuration: $animateDuration)
                                    .modifier(CustomAnimation( animateDuration: animateDuration, correctNumber: correctAnswer, choosenNumber: 0, isAnimating: is3dAnimation))
                                
                                FlagView(countryName: countries[1], callBack: {
                                    flaggedTapped(1)
                                }, isAnimating: $is3dAnimation, animateDuration: $animateDuration)
                                    .modifier(CustomAnimation( animateDuration: animateDuration, correctNumber: correctAnswer, choosenNumber: 1, isAnimating: is3dAnimation))
                                
                                FlagView(countryName: countries[2], callBack: {
                                    flaggedTapped(2)
                                }, isAnimating: $is3dAnimation, animateDuration: $animateDuration)
                                    .modifier(CustomAnimation( animateDuration: animateDuration, correctNumber: correctAnswer, choosenNumber: 2, isAnimating: is3dAnimation))
                            }.onAnimationCompleted(for: animateDuration) {
                                askQue()
                            }
                            
                        } .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Spacer()
                        Text("Score \(score)")
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.heavy))
                        Spacer()
                    }.padding()
                }
            }
        }
        //        .alert(scoreTitle, isPresented: $showAlert) {
        //            Button("Coninue", action: askQue)
        //        }
    }
    
    func flaggedTapped(_ number: Int) {
        if number == correctAnswer {
            scoreTitle = "Correct"
            score += 1
        } else {
            scoreTitle = "Wrong"
            score -= score == 0 ? 0: 1
        }
        noOfAttemptsLeft -= 1
        showAlert = true
        if noOfAttemptsLeft == 0 {
            noOfAttemptsLeft = 5
            scoreTitle = "You've reached maximum number of attempts."
        }
    }
    
    func askQue() {
        countries = countries.shuffled()
        correctAnswer = Int.random(in: 0...2)
        is3dAnimation = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 13 Pro Max")
    }
}


struct FlagView: View {
    var number: Int = 0
    var countryName = ""
    var callBack: ()->Void?
    @Binding var isAnimating: Bool
    @Binding var animateDuration: Double
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 4, damping: 2)) {
                animateDuration += 360
            }
            withAnimation {
                isAnimating = true
            }
            callBack()
        } label: {
            Image("\(countryName)")
                .renderingMode(.original)
                .clipShape(Capsule())
                .shadow(radius: 5)
        }
    }
}


struct CustomAnimation: ViewModifier {
    var animateDuration: Double
    var correctNumber: Int
    var choosenNumber: Int
    var isAnimating: Bool = false
    
    func body(content: Content) -> some View {
        if correctNumber == choosenNumber {
            content.rotation3DEffect(.degrees(animateDuration), axis: (x: 0, y: 1, z: 0))
        } else {
            content.opacity(isAnimating ? 0.25: 1)
                .scaleEffect(isAnimating ? 0.9: 1)
                .blur(radius: isAnimating ? 2: 0)
        }
    }
}


extension View {

    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}

// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {

    /// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
    var animatableData: Value {
        didSet {
            notifyCompletionIfFinished()
        }
    }

    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var targetValue: Value

    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void

    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        targetValue = observedValue
    }

    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard animatableData == targetValue else { return }

        /// Dispatching is needed to take the next runloop for the completion callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            self.completion()
        }
    }

    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
    }
}
