@startuml
title Modelo de Base de Datos ULima++\nVista horizontal por bloques

top to bottom direction
hide circle
skinparam linetype ortho
skinparam shadowing false
skinparam roundcorner 8
skinparam packageStyle rectangle
skinparam nodesep 35
skinparam ranksep 45
skinparam dpi 150
skinparam defaultFontSize 11
skinparam classAttributeIconSize 0
skinparam ArrowColor #444444
skinparam ArrowThickness 1
skinparam entity {
  BackgroundColor #FFFFFF
  BorderColor #333333
  FontColor #111111
  FontSize 10
}
skinparam package {
  FontStyle bold
  FontSize 12
  BorderColor #777777
}

package "1. Identidad y perfil academico" as PKG_IDENTIDAD #EAF3FF {
  entity "app_user" as app_user {
    * id <<PK>>
    --
      code <<UQ>>
      full_name
      institutional_email <<UQ>>
      password_hash
  }

  entity "student" as student {
    * id <<PK>>
    --
      user_id <<FK, UQ>>
      career_id
      curriculum_id
      current_level
      specialty_setup_completed
  }

  entity "career" as career {
    * id <<PK>>
    --
      code <<UQ>>
      name
      faculty
      is_active
  }

  entity "specialty" as specialty {
    * id <<PK>>
    --
      career_id <<FK>>
      name
      description
      is_active
  }

  entity "student_specialty" as student_specialty {
    * student_id <<PK, FK>>
    --
    * specialty_id <<PK, FK>>
      selection_type
      is_active
  }

}

package "2. Malla curricular (core)" as PKG_MALLA #EAF8EA {
  entity "curriculum" as curriculum {
    * id <<PK>>
    --
      career_id <<FK, UQ>>
      name
      is_active
  }

  entity "course" as course {
    * id <<PK>>
    --
      code <<UQ>>
      name
      default_credit
      origin_faculty
      is_active
  }

  entity "curriculum_course" as curriculum_course {
    * id <<PK>>
    --
      curriculum_id <<FK>>
      course_id <<FK>>
      cycle
      display_order
      credit
      category
      is_active
  }

  entity "curriculum_course_specialty" as curriculum_course_specialty {
    * curriculum_course_id <<PK, FK>>
    --
    * specialty_id <<PK, FK>>
  }

  entity "course_prerequisite" as course_prerequisite {
    * id <<PK>>
    --
      curriculum_id <<FK>>
      curriculum_course_id <<FK>>
      prerequisite_type
      prerequisite_curriculum_course_id <<FK>>
      required_cycle
  }

  entity "student_course_progress" as student_course_progress {
    * id <<PK>>
    --
      student_id <<FK>>
      curriculum_id <<FK>>
      curriculum_course_id <<FK>>
      status
  }

  entity "student_curriculum_simulation" as student_curriculum_simulation {
    * id <<PK>>
    --
      student_id <<FK>>
      curriculum_id <<FK>>
      curriculum_course_id <<FK>>
      status
  }

}

package "3. Oferta academica y matricula" as PKG_OFERTA #FFF6DB {
  entity "academic_period" as academic_period {
    * id <<PK>>
    --
      code <<UQ>>
      start_date
      end_date
      is_active
  }

  entity "academic_week" as academic_week {
    * id <<PK>>
    --
      academic_period_id <<FK>>
      week_number
      start_date
      end_date
  }

  entity "course_offering" as course_offering {
    * id <<PK>>
    --
      academic_period_id <<FK>>
      course_id <<FK>>
  }

  entity "teacher" as teacher {
    * id <<PK>>
    --
      teacher_code <<UQ>>
      full_name
      institutional_email <<UQ>>
  }

  entity "section" as section {
    * id <<PK>>
    --
      course_offering_id <<FK>>
      teacher_id <<FK>>
      code
  }

  entity "enrollment" as enrollment {
    * id <<PK>>
    --
      student_id <<FK>>
      section_id <<FK>>
      status
      attended_hours
      absent_hours
      total_hours
  }

}

package "4. Horarios y asesorias" as PKG_HORARIOS #FFF0E5 {
  entity "schedule_session" as schedule_session {
    * id <<PK>>
    --
      section_id <<FK>>
      day_of_week
      start_time
      end_time
      classroom
      color_hex
  }

  entity "course_advising_session" as course_advising_session {
    * id <<PK>>
    --
      course_offering_id <<FK>>
      section_id <<FK>>
      teacher_id <<FK>>
      day_of_week
      start_time
      end_time
      classroom
      meeting_url
      modality
      note
  }

}

package "5. Silabos, evaluaciones y notas" as PKG_SILABOS #F1EAFF {
  entity "syllabus" as syllabus {
    * id <<PK>>
    --
      course_offering_id <<FK, UQ>>
      title
      drive_file_id <<UQ>>
      drive_file_url
  }

  entity "assessment_type" as assessment_type {
    * id <<PK>>
    --
      name <<UQ>>
      abbreviation
      description
  }

  entity "assessment" as assessment {
    * id <<PK>>
    --
      syllabus_id <<FK>>
      assessment_type_id <<FK>>
      code
      name
      week_number
      weight
  }

  entity "student_score" as student_score {
    * id <<PK>>
    --
      enrollment_id <<FK>>
      assessment_id <<FK>>
      value
  }

}

package "6. Comunicacion y alertas" as PKG_COMUNICACION #FFEAF3 {
  entity "section_representative" as section_representative {
    * id <<PK>>
    --
      section_id <<FK>>
      enrollment_id <<FK, UQ>>
      position
      is_active
  }

  entity "announcement" as announcement {
    * id <<PK>>
    --
      section_representative_id <<FK>>
      title
      message
      published_at
      is_active
  }

  entity "alert" as alert {
    * id <<PK>>
    --
      student_id <<FK>>
      type
      title
      message
      is_read
      created_at
  }

}

' Guias invisibles recuperadas del estilo horizontal del SVG base.
' Mantienen Malla curricular cerca del centro por sus dependencias principales.
student -[hidden]right- enrollment
enrollment -[hidden]right- curriculum_course
curriculum_course -[hidden]right- schedule_session
schedule_session -[hidden]right- assessment
assessment -[hidden]right- section_representative

app_user -[hidden]down- student
student -[hidden]down- enrollment
career -[hidden]down- curriculum
curriculum -[hidden]down- curriculum_course
course -[hidden]down- course_offering
course_offering -[hidden]down- syllabus
section -[hidden]down- schedule_session
enrollment -[hidden]down- student_score
academic_period -[hidden]down- academic_week
section_representative -[hidden]down- announcement

' Relaciones FK reales; sin etiquetas para mejorar legibilidad
academic_period ||--o{ academic_week
student ||--o{ alert
section_representative ||--o{ announcement
assessment_type ||--o{ assessment
syllabus ||--o{ assessment
section |o..o{ course_advising_session
teacher ||--o{ course_advising_session
course_offering ||--o{ course_advising_session
course ||--o{ course_offering
academic_period ||--o{ course_offering
curriculum ||--o{ course_prerequisite
curriculum_course |o..o{ course_prerequisite
curriculum_course ||--o{ course_prerequisite
career ||--|| curriculum
course ||--o{ curriculum_course
curriculum ||--o{ curriculum_course
curriculum_course ||--o{ curriculum_course_specialty
specialty ||--o{ curriculum_course_specialty
section ||--o{ enrollment
student ||--o{ enrollment
section ||--o{ schedule_session
teacher ||--o{ section
course_offering ||--o{ section
section ||--o{ section_representative
enrollment ||--|| section_representative
career ||--o{ specialty
app_user ||--|| student
curriculum ||--o{ student_course_progress
curriculum_course ||--o{ student_course_progress
student ||--o{ student_course_progress
student ||--o{ student_curriculum_simulation
curriculum ||--o{ student_curriculum_simulation
curriculum_course ||--o{ student_curriculum_simulation
assessment ||--o{ student_score
enrollment ||--o{ student_score
student ||--o{ student_specialty
specialty ||--o{ student_specialty
course_offering ||--|| syllabus

caption Vista por bloques: 27 tablas, 145 atributos resumidos y 38 claves foraneas reales.

@enduml
