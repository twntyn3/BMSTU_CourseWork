package main

import (
	"fmt"
	"os"
)

type Task struct {
	start, end int
}

type TaskStack struct {
	tasks    []Task
	top      int
	capacity int
}

func NewTaskStack(capacity int) *TaskStack {
	return &TaskStack{
		tasks:    make([]Task, capacity),
		top:      -1,
		capacity: capacity,
	}
}

func (s *TaskStack) Push(t Task) {
	if s.top >= s.capacity-1 {
		s.capacity *= 2
		newTasks := make([]Task, len(s.tasks), s.capacity)
		copy(newTasks, s.tasks)
		s.tasks = newTasks
	}
	s.top++
	if s.top < len(s.tasks) {
		s.tasks[s.top] = t
	} else {
		s.tasks = append(s.tasks, t)
	}
}

func (s *TaskStack) Pop() Task {
	if s.IsEmpty() {
		panic("stack is empty")
	}
	task := s.tasks[s.top]
	s.top--
	return task
}

func (s *TaskStack) IsEmpty() bool {
	return s.top == -1
}

func qssort(n int, less func(i, j int) bool, swap func(i, j int)) {
	stack := NewTaskStack(n)
	stack.Push(Task{0, n - 1})

	for !stack.IsEmpty() {
		task := stack.Pop()
		low, high := task.start, task.end

		if low < high {
			pivot := low + (high-low)/2
			swap(pivot, high)
			storeIndex := low

			for i := low; i < high; i++ {
				if less(i, high) {
					swap(i, storeIndex)
					storeIndex++
				}
			}
			swap(storeIndex, high)

			if storeIndex-1 > low {
				stack.Push(Task{low, storeIndex - 1})
			}
			if storeIndex+1 < high {
				stack.Push(Task{storeIndex + 1, high})
			}
		}
	}
}

func main() {
	var n int
	if _, err := fmt.Scan(&n); err != nil || n <= 0 {
		fmt.Fprintln(os.Stderr, "инвалид")
		return
	}

	items := make([]int, n)
	for i := 0; i < n; i++ {
		if _, err := fmt.Scan(&items[i]); err != nil {
			fmt.Fprintln(os.Stderr, "инвалид.")
			return
		}
	}

	qssort(len(items),
		func(i, j int) bool { return items[i] < items[j] },
		func(i, j int) { items[i], items[j] = items[j], items[i] })

	for _, val := range items {
		fmt.Println(val)
	}
}
